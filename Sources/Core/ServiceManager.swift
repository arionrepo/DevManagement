// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Sources/Core/ServiceManager.swift
// Description: Manages service lifecycle operations (start, stop, restart) and status checking
// Author: Libor Ballaty <libor@arionetworks.com>
// Created: 2025-12-13

import Foundation

public class ServiceManager {
    public init() {}

    public func getStatus(for service: Service) throws -> ServiceStatus {
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

    public func checkHealth(for service: Service) throws -> ServiceStatus {
        return try getStatus(for: service)
    }

    public func start(service: Service) throws {
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

    public func stop(service: Service) throws {
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

    public func restart(service: Service) throws {
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
        // Special handling for colima profile status checks
        if service.id.hasPrefix("colima-") && service.colimaProfile != nil {
            return try checkColimaProfileStatus(service)
        }

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

    private func checkColimaProfileStatus(_ service: Service) throws -> ServiceStatus {
        // Use colima list --json to check profile status and resources
        let profileName = service.colimaProfile ?? "default"

        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "colima list --json 2>/dev/null | grep -A 10 '\"name\":\"\(profileName)\"'"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {

                // Parse JSON to extract status and resources
                if let jsonData = output.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {

                    let status = json["status"] as? String ?? "Unknown"
                    let cpus = json["cpus"] as? Int
                    let memory = json["memory"] as? Int
                    let memoryGb = memory.map { Double($0) / 1_073_741_824 }

                    if status == "Running" {
                        return ServiceStatus(icon: "🟢", description: "Running", cpus: cpus, memory_gb: memoryGb)
                    } else {
                        return ServiceStatus(icon: "🔴", description: "Stopped", cpus: cpus, memory_gb: memoryGb)
                    }
                }
            }

            // Fallback to simple status check
            let statusProcess = Process()
            statusProcess.launchPath = "/bin/bash"
            statusProcess.arguments = ["-c", "colima status \(profileName)"]

            let statusPipe = Pipe()
            statusProcess.standardOutput = statusPipe
            statusProcess.standardError = statusPipe

            try statusProcess.run()
            statusProcess.waitUntilExit()

            if statusProcess.terminationStatus == 0 {
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
        let startTime = Date()

        let task = session.dataTask(with: request) { _, response, _ in
            let latency = Int((Date().timeIntervalSince(startTime)) * 1000)

            if let httpResponse = response as? HTTPURLResponse {
                let expectedCodes = endpoint.expectedStatusCodes ?? [200]
                if expectedCodes.contains(httpResponse.statusCode) {
                    resultStatus = ServiceStatus(icon: "🟢", description: "Healthy", latency_ms: latency)
                } else {
                    resultStatus = ServiceStatus(icon: "🟠", description: "HTTP \(httpResponse.statusCode)", latency_ms: latency)
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
