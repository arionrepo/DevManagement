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
        for service in services {
            let statusSymbol = "❓"  // Placeholder - Phase 3 will implement actual checks
            print("  \(statusSymbol) \(service.displayName)")
        }
        print()
    }

    static func handleStart(services: [Service], serviceName: String?) throws {
        if let name = serviceName {
            print("Starting service: \(name)")
            // Phase 2 will implement actual start logic
        } else {
            print("Please specify a service name")
        }
    }

    static func handleStop(services: [Service], serviceName: String?) throws {
        if let name = serviceName {
            print("Stopping service: \(name)")
            // Phase 2 will implement actual stop logic
        } else {
            print("Please specify a service name")
        }
    }

    static func handleRestart(services: [Service], serviceName: String?) throws {
        if let name = serviceName {
            print("Restarting service: \(name)")
            // Phase 2 will implement actual restart logic
        } else {
            print("Please specify a service name")
        }
    }

    static func handleHealthCheck(services: [Service]) throws {
        print("\n🏥 Health Check Status\n")
        for service in services {
            print("  ❓ \(service.displayName)")
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
