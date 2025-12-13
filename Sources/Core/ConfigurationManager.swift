// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Sources/Core/ConfigurationManager.swift
// Description: Loads and manages service configuration from services.json
// Author: Libor Ballaty <libor@arionetworks.com>
// Created: 2025-12-13

import Foundation

public class ConfigurationManager {
    let configPath: String

    public init() {
        // Default to project config directory
        self.configPath = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/config/services.json"
    }

    public func loadServices() throws -> [Service] {
        let url = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let config = try decoder.decode(ServiceConfiguration.self, from: data)
        return config.services
    }
}
