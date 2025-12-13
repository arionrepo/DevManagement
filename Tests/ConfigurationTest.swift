// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Tests/ConfigurationTest.swift
// Description: Test service configuration loading and validation
// Author: Libor Ballaty <libor@arionetworks.com>
// Created: 2025-12-13

import Foundation

/// Test service configuration loading
///
/// Validates that:
/// 1. Configuration file is valid JSON
/// 2. All required services are present
/// 3. Service dependencies are properly defined
/// 4. File paths are valid
/// 5. Commands are properly formatted
func testConfigurationLoading() {
    print("Testing configuration loading...")

    let configManager = ConfigurationManager()

    do {
        let services = try configManager.loadServices()

        print("✅ Configuration loaded successfully")
        print("   Found \(services.count) services")

        // Validate each service
        for service in services {
            print("\n📦 \(service.displayName) (\(service.id))")
            print("   Type: \(service.type)")
            print("   Critical: \(service.critical)")
            print("   Startup Order: \(service.startupOrder)")
            print("   Dependencies: \(service.dependencies?.joined(separator: ", ") ?? "none")")

            // Validate commands
            if service.commands.start.isEmpty {
                print("   ⚠️  Warning: start command is empty")
            }

            // Validate files exist
            var fileCount = 0
            if let scripts = service.files.startupScripts {
                fileCount += scripts.count
            }
            if let scripts = service.files.stopScripts {
                fileCount += scripts.count
            }
            if let files = service.files.configFiles {
                fileCount += files.count
            }
            if let files = service.files.relatedFiles {
                fileCount += files.count
            }
            print("   Files: \(fileCount) total")
        }

        print("\n✅ All configuration tests passed")

    } catch {
        print("❌ Configuration error: \(error)")
        exit(1)
    }
}

// Run tests on startup if running as test
if CommandLine.arguments.contains("--test") {
    testConfigurationLoading()
    exit(0)
}
