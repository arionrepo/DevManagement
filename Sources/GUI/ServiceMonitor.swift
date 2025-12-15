import Foundation
import Combine
import DevManagementCore

@MainActor
class ServiceMonitor: ObservableObject {
    @Published var services: [ServiceStatusItem] = []
    @Published var lastUpdate: Date = Date()
    @Published var isMonitoring: Bool = false
    @Published var overallStatus: String = "Unknown"

    private let configManager = ConfigurationManager()
    private let serviceManager = ServiceManager()
    private var timer: Timer?
    private var updateTask: Task<Void, Never>?

    init() {
        loadServices()
    }

    func loadServices() {
        do {
            let loadedServices = try configManager.loadServices()

            // Detect colima profiles first
            let colimaProfiles = detectColimaProfiles()
            var serviceItems: [ServiceStatusItem] = []

            // Add colima profiles at the top
            for profile in colimaProfiles {
                if let profileService = createColimaProfileService(profileName: profile) {
                    serviceItems.append(ServiceStatusItem(service: profileService, status: nil))
                }
            }

            // Add other services, filtering out the generic "colima" service
            for service in loadedServices where service.id != "colima" {
                serviceItems.append(ServiceStatusItem(service: service, status: nil))
            }

            self.services = serviceItems
            updateStatus()
        } catch {
            print("❌ Failed to load services: \(error)")
        }
    }

    private func detectColimaProfiles() -> [String] {
        let colimaDir = NSHomeDirectory() + "/.colima"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: colimaDir) else {
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: colimaDir)
            // Filter for profile directories (skip _lima, ssh_config, etc.)
            return contents.filter { item in
                !item.hasPrefix(".") && !item.hasPrefix("_") && item != "ssh_config"
            }.sorted()
        } catch {
            print("⚠️  Failed to read colima profiles: \(error)")
            return []
        }
    }

    private func createColimaProfileService(profileName: String) -> Service? {
        // Create a synthetic Service for colima profile monitoring
        let profileService = Service(
            id: "colima-\(profileName)",
            name: "colima-\(profileName)",
            displayName: "Colima: \(profileName)",
            type: "process",
            icon: "🐳",
            description: "Docker runtime profile: \(profileName)",
            startupOrder: 100,  // Not in startup order
            critical: false,
            startupDelaySeconds: 0,
            commands: Commands(
                start: "colima start \(profileName)",
                stop: "colima stop \(profileName)",
                restart: "colima stop \(profileName) && colima start \(profileName)",
                status: "colima status \(profileName)"
            ),
            healthCheck: HealthCheck(
                type: "command",
                endpoints: nil,
                command: "colima status \(profileName)",
                expectedOutputPattern: "running",
                timeoutSeconds: 5,
                intervalSeconds: 3,
                expectedStatusCodes: nil
            ),
            ports: nil,
            files: FileMapping(),
            dependencies: nil,
            notes: "Colima profile: \(profileName)",
            colimaProfile: profileName
        )
        return profileService
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Initial status check
        updateStatus()

        // Set up timer for periodic updates
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatus()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    func updateStatus() {
        updateTask?.cancel()
        updateTask = Task {
            for index in 0..<services.count {
                let service = services[index].service
                do {
                    let status = try serviceManager.getStatus(for: service)
                    services[index].status = status
                } catch {
                    services[index].status = ServiceStatus(icon: "❌", description: "Check failed")
                }
            }
            lastUpdate = Date()
            updateOverallStatus()
        }
    }

    func start(service: Service) {
        print("🚀 Starting \(service.displayName)...")
        do {
            try serviceManager.start(service: service)
            updateStatus()
        } catch {
            print("❌ Failed to start \(service.displayName): \(error)")
        }
    }

    func stop(service: Service) {
        print("⛔ Stopping \(service.displayName)...")
        do {
            try serviceManager.stop(service: service)
            updateStatus()
        } catch {
            print("❌ Failed to stop \(service.displayName): \(error)")
        }
    }

    func restart(service: Service) {
        print("🔄 Restarting \(service.displayName)...")
        do {
            try serviceManager.restart(service: service)
            updateStatus()
        } catch {
            print("❌ Failed to restart \(service.displayName): \(error)")
        }
    }

    private func updateOverallStatus() {
        let criticalServices = services.filter { $0.service.critical }
        let criticalHealthy = criticalServices.filter { item in
            item.status?.icon == "🟢"
        }.count

        if criticalHealthy == criticalServices.count && criticalServices.count > 0 {
            overallStatus = "🟢 Healthy"
        } else if criticalHealthy > 0 {
            overallStatus = "🟠 Degraded"
        } else {
            overallStatus = "🔴 Failed"
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }
}

struct ServiceStatusItem {
    let service: Service
    var status: ServiceStatus?

    var displayName: String {
        service.displayName
    }

    var icon: String {
        status?.icon ?? "❓"
    }

    var statusDescription: String {
        status?.description ?? "Loading..."
    }

    var isRunning: Bool {
        status?.icon == "🟢"
    }

    var endpoint: String? {
        if let healthCheck = service.healthCheck,
           let endpoints = healthCheck.endpoints,
           !endpoints.isEmpty {
            return endpoints.first?.url
        }
        return nil
    }

    var latency_ms: Int? {
        status?.latency_ms
    }

    var uptime: String? {
        status?.uptime
    }

    var cpus: Int? {
        status?.cpus
    }

    var memory_gb: Double? {
        status?.memory_gb
    }
}
