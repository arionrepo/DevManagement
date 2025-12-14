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
            self.services = loadedServices.map { service in
                ServiceStatusItem(service: service, status: nil)
            }
            updateStatus()
        } catch {
            print("❌ Failed to load services: \(error)")
        }
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
}
