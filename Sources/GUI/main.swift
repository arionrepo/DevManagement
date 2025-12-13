// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Sources/GUI/main.swift
// Description: SwiftUI MenuBarExtra application for DevManagement service lifecycle
// Author: Libor Ballaty <libor@arionetworks.com>
// Created: 2025-12-13

import SwiftUI
import DevManagementCore

@available(macOS 13.0, *)
@main
struct DevManagementApp: App {
    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 12) {
                Text("⚙️ Development Services")
                    .font(.headline)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("🟢 Colima - Running")
                    Text("🟢 Supabase - Healthy")
                    Text("🟢 Python Backend - Healthy")
                    Text("🟠 Admin UI - No health check")
                    Text("🔴 Customer UI - Stopped")
                }
                .font(.caption)

                Divider()

                HStack {
                    Button("Start All") {
                        // TODO: Implement start all
                    }
                    Button("Stop All") {
                        // TODO: Implement stop all
                    }
                }

                Divider()

                HStack {
                    Text("Last: 12:34 PM")
                        .font(.caption2)
                    Spacer()
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(12)
            .frame(width: 320)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "gear.circle.fill")
                    .foregroundColor(.green)
                Text("Dev")
                    .font(.system(size: 12))
            }
        }
    }
}
