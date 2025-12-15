// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Sources/Core/Models.swift
// Description: Data models for DevManagement service lifecycle configuration and status
// Author: Libor Ballaty <libor@arionetworks.com>
// Created: 2025-12-13

import Foundation

// MARK: - Configuration Models

public struct ServiceConfiguration: Codable {
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

public struct Service: Codable {
    public let id: String
    public let name: String
    public let displayName: String
    public let type: String
    public let icon: String
    public let description: String
    public let startupOrder: Int
    public let critical: Bool
    public let startupDelaySeconds: Int
    public let commands: Commands
    public let healthCheck: HealthCheck?
    public let ports: [PortMapping]?
    public let files: FileMapping
    public let dependencies: [String]?
    public let notes: String?

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

public struct Commands: Codable {
    let start: String
    let stop: String
    let restart: String
    let status: String?
}

public struct HealthCheck: Codable {
    public let type: String
    public let endpoints: [HealthCheckEndpoint]?
    public let command: String?
    public let expectedOutputPattern: String?
    public let timeoutSeconds: Int?
    public let intervalSeconds: Int?
    public let expectedStatusCodes: [Int]?

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

public struct HealthCheckEndpoint: Codable {
    public let url: String
    public let expectedStatusCodes: [Int]?
    public let description: String?

    enum CodingKeys: String, CodingKey {
        case url
        case expectedStatusCodes = "expected_status_codes"
        case description
    }
}

public struct PortMapping: Codable {
    let name: String
    let port: Int
    let `protocol`: String
}

public struct FileMapping: Codable {
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

public struct FileReference: Codable {
    let name: String
    let path: String
    let description: String?
}

public struct GlobalSettings: Codable {
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

public struct FutureService: Codable {
    let displayName: String
    let description: String
    let estimatedPhase: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case description
        case estimatedPhase = "estimated_phase"
    }
}

// MARK: - Status Models

public struct ServiceStatus {
    public let icon: String
    public let description: String
    public let latency_ms: Int?
    public let uptime: String?

    public init(icon: String, description: String, latency_ms: Int? = nil, uptime: String? = nil) {
        self.icon = icon
        self.description = description
        self.latency_ms = latency_ms
        self.uptime = uptime
    }
}
