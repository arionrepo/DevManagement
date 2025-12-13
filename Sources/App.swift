// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Sources/App.swift
// Description: Main entry point for DevManagement application
// Author: Libor Ballaty <libor@arionetworks.com>
// Created: 2025-12-13

import Foundation

/// DevManagement - Service lifecycle management for ArionComply development environment
///
/// Business Purpose: Automatically detect when the macOS system wakes from sleep and
/// intelligently recover services (Supabase, Python Backend, UIs) to prevent manual
/// restart requirements and reduce development friction.
///
/// Current Phase: 1 - Project Infrastructure (Config and Models)
///
/// Usage:
///   dev-manager status              # Show all service statuses
///   dev-manager start SERVICE       # Start a specific service
///   dev-manager stop SERVICE        # Stop a specific service
///   dev-manager restart SERVICE     # Restart a specific service
///   dev-manager start-all           # Start all critical services
///   dev-manager stop-all            # Stop all services
///   dev-manager health-check        # Perform health checks

@main
struct DevManagement {
    static func main() {
        // Phase 1: Parse configuration
        let configManager = ConfigurationManager()

        // Phase 2: Parse command line arguments
        let arguments = CommandLine.arguments
        guard arguments.count > 1 else {
            printUsage()
            exit(1)
        }

        let command = arguments[1]

        do {
            // Load services configuration
            let services = try configManager.loadServices()

            // Phase 3: Route command to appropriate handler
            switch command {
            case "status":
                try handleStatus(services: services)

            case "start":
                let serviceName = arguments.count > 2 ? arguments[2] : nil
                try handleStart(services: services, serviceName: serviceName)

            case "stop":
                let serviceName = arguments.count > 2 ? arguments[2] : nil
                try handleStop(services: services, serviceName: serviceName)

            case "restart":
                let serviceName = arguments.count > 2 ? arguments[2] : nil
                try handleRestart(services: services, serviceName: serviceName)

            case "health-check":
                try handleHealthCheck(services: services)

            default:
                print("Unknown command: \(command)")
                printUsage()
                exit(1)
            }
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }

    // MARK: - Command Handlers

    static func handleStatus(services: [Service]) throws {
        print("\n🔍 Service Status Report\n")
        let serviceManager = ServiceManager()

        for service in services {
            let status = try serviceManager.getStatus(for: service)
            print("  \(status.icon) \(service.displayName) - \(status.description)")
        }
        print()
    }

    static func handleStart(services: [Service], serviceName: String?) throws {
        guard let name = serviceName else {
            print("❌ Please specify a service name")
            print("\nAvailable services:")
            for service in services {
                print("  - \(service.name)")
            }
            exit(1)
        }

        guard let service = services.first(where: { $0.name == name }) else {
            print("❌ Service not found: \(name)")
            exit(1)
        }

        let serviceManager = ServiceManager()
        try serviceManager.start(service: service)
    }

    static func handleStop(services: [Service], serviceName: String?) throws {
        guard let name = serviceName else {
            print("❌ Please specify a service name")
            print("\nAvailable services:")
            for service in services {
                print("  - \(service.name)")
            }
            exit(1)
        }

        guard let service = services.first(where: { $0.name == name }) else {
            print("❌ Service not found: \(name)")
            exit(1)
        }

        let serviceManager = ServiceManager()
        try serviceManager.stop(service: service)
    }

    static func handleRestart(services: [Service], serviceName: String?) throws {
        guard let name = serviceName else {
            print("❌ Please specify a service name")
            print("\nAvailable services:")
            for service in services {
                print("  - \(service.name)")
            }
            exit(1)
        }

        guard let service = services.first(where: { $0.name == name }) else {
            print("❌ Service not found: \(name)")
            exit(1)
        }

        let serviceManager = ServiceManager()
        try serviceManager.restart(service: service)
    }

    static func handleHealthCheck(services: [Service]) throws {
        print("\n🏥 Health Check Status\n")
        let serviceManager = ServiceManager()

        for service in services {
            let status = try serviceManager.checkHealth(for: service)
            print("  \(status.icon) \(service.displayName) - \(status.description)")
        }
        print()
    }

    static func printUsage() {
        print("""

        DevManagement - ArionComply Service Lifecycle Manager

        Usage:
          dev-manager status              Show status of all services
          dev-manager start SERVICE       Start a specific service
          dev-manager stop SERVICE        Stop a specific service
          dev-manager restart SERVICE     Restart a specific service
          dev-manager start-all           Start all critical services
          dev-manager stop-all            Stop all services
          dev-manager health-check        Run health checks on all services

        Examples:
          dev-manager status
          dev-manager start supabase
          dev-manager restart python-backend
          dev-manager start-all

        """)
    }
}

// MARK: - Configuration Management

class ConfigurationManager {
    let configPath: String

    init() {
        // Default to project config directory
        self.configPath = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/config/services.json"
    }

    func loadServices() throws -> [Service] {
        let url = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let config = try decoder.decode(ServiceConfiguration.self, from: data)
        return config.services
    }
}

// MARK: - Data Models (Phase 1 - Configuration Structures)

struct ServiceConfiguration: Codable {
    let version: String
    let description: String
    let services: [Service]
    let globalSettings: GlobalSettings?
    let futureServices: [String: FutureService]?

    enum CodingKeys: String, CodingKey {
        case version
        case description
        case services
        case globalSettings = "global_settings"
        case futureServices = "future_services"
    }
}

struct Service: Codable {
    let id: String
    let name: String
    let displayName: String
    let type: String
    let icon: String
    let description: String
    let startupOrder: Int
    let critical: Bool
    let startupDelaySeconds: Int
    let commands: Commands
    let healthCheck: HealthCheck?
    let ports: [PortMapping]?
    let files: FileMapping
    let dependencies: [String]?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName = "display_name"
        case type
        case icon
        case description
        case startupOrder = "startup_order"
        case critical
        case startupDelaySeconds = "startup_delay_seconds"
        case commands
        case healthCheck = "health_check"
        case ports
        case files
        case dependencies
        case notes
    }
}

struct Commands: Codable {
    let start: String
    let stop: String
    let restart: String
    let status: String?
}

struct HealthCheck: Codable {
    let type: String
    let endpoints: [HealthCheckEndpoint]?
    let command: String?
    let expectedOutputPattern: String?
    let timeoutSeconds: Int?
    let intervalSeconds: Int?
    let expectedStatusCodes: [Int]?

    enum CodingKeys: String, CodingKey {
        case type
        case endpoints
        case command
        case expectedOutputPattern = "expected_output_pattern"
        case timeoutSeconds = "timeout_seconds"
        case intervalSeconds = "interval_seconds"
        case expectedStatusCodes = "expected_status_codes"
    }
}

struct HealthCheckEndpoint: Codable {
    let url: String
    let expectedStatusCodes: [Int]?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case url
        case expectedStatusCodes = "expected_status_codes"
        case description
    }
}

struct PortMapping: Codable {
    let name: String
    let port: Int
    let `protocol`: String
}

struct FileMapping: Codable {
    let startupScripts: [FileReference]?
    let stopScripts: [FileReference]?
    let configFiles: [FileReference]?
    let relatedFiles: [FileReference]?

    enum CodingKeys: String, CodingKey {
        case startupScripts = "startup_scripts"
        case stopScripts = "stop_scripts"
        case configFiles = "config_files"
        case relatedFiles = "related_files"
    }
}

struct FileReference: Codable {
    let name: String
    let path: String
    let description: String?
}

struct GlobalSettings: Codable {
    let autoStartOnWake: Bool?
    let autoRecoverOnWake: Bool?
    let healthCheckIntervalSeconds: Int?
    let healthCheckTimeoutSeconds: Int?
    let logDirectory: String?
    let pidDirectory: String?

    enum CodingKeys: String, CodingKey {
        case autoStartOnWake = "auto_start_on_wake"
        case autoRecoverOnWake = "auto_recover_on_wake"
        case healthCheckIntervalSeconds = "health_check_interval_seconds"
        case healthCheckTimeoutSeconds = "health_check_timeout_seconds"
        case logDirectory = "log_directory"
        case pidDirectory = "pid_directory"
    }
}

struct FutureService: Codable {
    let displayName: String
    let description: String
    let estimatedPhase: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case description
        case estimatedPhase = "estimated_phase"
    }
}

// MARK: - Service Manager (Phase 2)

class ServiceManager {
    func getStatus(for service: Service) throws -> ServiceStatus {
        // For process type services (Colima), check with command
        if service.type == "process" {
            return try checkProcessStatus(service)
        }

        // For HTTP services, check health endpoint
        if service.type == "http" {
            return try checkHttpStatus(service)
        }

        return ServiceStatus(icon: "❓", description: "Unknown status")
    }

    func checkHealth(for service: Service) throws -> ServiceStatus {
        return try getStatus(for: service)
    }

    func start(service: Service) throws {
        print("\n🚀 Starting \(service.displayName)...")

        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", service.commands.start]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ \(service.displayName) started successfully")
            } else {
                print("❌ \(service.displayName) startup failed (exit code: \(process.terminationStatus))")
                exit(1)
            }
        } catch {
            print("❌ Failed to start \(service.displayName): \(error)")
            exit(1)
        }
    }

    func stop(service: Service) throws {
        print("\n⛔ Stopping \(service.displayName)...")

        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", service.commands.stop]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ \(service.displayName) stopped")
            } else {
                print("⚠️  \(service.displayName) stop returned exit code: \(process.terminationStatus)")
            }
        } catch {
            print("❌ Failed to stop \(service.displayName): \(error)")
            exit(1)
        }
    }

    func restart(service: Service) throws {
        print("\n🔄 Restarting \(service.displayName)...")

        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", service.commands.restart]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ \(service.displayName) restarted successfully")
            } else {
                print("❌ \(service.displayName) restart failed (exit code: \(process.terminationStatus))")
                exit(1)
            }
        } catch {
            print("❌ Failed to restart \(service.displayName): \(error)")
            exit(1)
        }
    }

    // MARK: - Status Checking

    private func checkProcessStatus(_ service: Service) throws -> ServiceStatus {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", service.commands.status ?? "true"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return ServiceStatus(icon: "🟢", description: "Running")
            } else {
                return ServiceStatus(icon: "🔴", description: "Stopped")
            }
        } catch {
            return ServiceStatus(icon: "🔴", description: "Status check failed")
        }
    }

    private func checkHttpStatus(_ service: Service) throws -> ServiceStatus {
        // For Supabase, first verify Docker containers are running
        if service.id == "supabase" {
            if !checkDockerContainers(serviceName: "supabase", requiredCount: 5) {
                return ServiceStatus(icon: "🔴", description: "Containers stopped")
            }
        }

        guard let healthCheck = service.healthCheck,
              let endpoints = healthCheck.endpoints,
              !endpoints.isEmpty else {
            return ServiceStatus(icon: "❓", description: "No health check configured")
        }

        for endpoint in endpoints {
            if let status = try checkHttpEndpoint(endpoint) {
                return status
            }
        }

        return ServiceStatus(icon: "🔴", description: "Health check failed")
    }

    private func checkDockerContainers(serviceName: String, requiredCount: Int) -> Bool {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "docker ps --filter \"name=\(serviceName)\" --format \"{{.Names}}\" 2>/dev/null | wc -l | tr -d ' '"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               let count = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return count >= requiredCount
            }
        } catch {
            return false
        }

        return false
    }

    private func checkHttpEndpoint(_ endpoint: HealthCheckEndpoint) throws -> ServiceStatus? {
        let urlString = endpoint.url
        guard let url = URL(string: urlString) else {
            return nil
        }

        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default)

        var resultStatus: ServiceStatus? = nil
        let semaphore = DispatchSemaphore(value: 0)

        let task = session.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                let expectedCodes = endpoint.expectedStatusCodes ?? [200]
                if expectedCodes.contains(httpResponse.statusCode) {
                    resultStatus = ServiceStatus(icon: "🟢", description: "Healthy")
                } else {
                    resultStatus = ServiceStatus(icon: "🟠", description: "HTTP \(httpResponse.statusCode)")
                }
            }
            semaphore.signal()
        }

        task.resume()

        // Wait up to 5 seconds for response
        let deadline = DispatchTime.now() + .seconds(5)
        if semaphore.wait(timeout: deadline) == .timedOut {
            return ServiceStatus(icon: "🔴", description: "Health check timeout")
        }

        return resultStatus
    }
}

// MARK: - Service Status

struct ServiceStatus {
    let icon: String
    let description: String
}
