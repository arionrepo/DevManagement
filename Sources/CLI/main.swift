// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Sources/CLI/main.swift
// Description: Command-line interface for DevManagement service lifecycle manager
// Author: Libor Ballaty <libor@arionetworks.com>
// Created: 2025-12-13

import Foundation
import DevManagementCore

/// DevManagement - Service lifecycle management for ArionComply development environment
///
/// Business Purpose: Automatically detect when the macOS system wakes from sleep and
/// intelligently recover services (Supabase, Python Backend, UIs) to prevent manual
/// restart requirements and reduce development friction.
///
/// Usage:
///   dev-manager-cli status              # Show all service statuses
///   dev-manager-cli start SERVICE       # Start a specific service
///   dev-manager-cli stop SERVICE        # Stop a specific service
///   dev-manager-cli restart SERVICE     # Restart a specific service
///   dev-manager-cli health-check        # Perform health checks

@main
struct DevManagementCLI {
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

        DevManagement - ArionComply Service Lifecycle Manager (CLI)

        Usage:
          dev-manager-cli status              Show status of all services
          dev-manager-cli start SERVICE       Start a specific service
          dev-manager-cli stop SERVICE        Stop a specific service
          dev-manager-cli restart SERVICE     Restart a specific service
          dev-manager-cli health-check        Run health checks on all services

        Examples:
          dev-manager-cli status
          dev-manager-cli start supabase
          dev-manager-cli restart python-backend
          dev-manager-cli health-check

        """)
    }
}
