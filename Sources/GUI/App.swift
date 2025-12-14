import SwiftUI
import DevManagementCore

/// SwiftUI MenuBarExtra application for DevManagement service lifecycle
/// File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/Sources/GUI/main.swift
/// Author: Libor Ballaty <libor@arionetworks.com>
/// Created: 2025-12-13

@main
@available(macOS 13.0, *)
struct DevManagementApp: App {
    @StateObject private var monitor = ServiceMonitor()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("⚙️ Development Services")
                        .font(.headline)
                    Spacer()
                    Button(action: { monitor.updateStatus() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(0..<monitor.services.count, id: \.self) { index in
                            let item = monitor.services[index]
                            HStack {
                                Text(item.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayName)
                                        .font(.caption)
                                    Text(item.statusDescription)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: { monitor.restart(service: item.service) }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)

                Divider()

                HStack(spacing: 8) {
                    Button(action: { startAll() }) {
                        Text("Start All")
                            .font(.caption)
                    }
                    Button(action: { stopAll() }) {
                        Text("Stop All")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status: \(monitor.overallStatus)")
                            .font(.caption2)
                        Text(formatLastUpdate(monitor.lastUpdate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Text("Quit")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(12)
            .frame(width: 340)
            .onAppear {
                monitor.startMonitoring()
            }
            .onDisappear {
                monitor.stopMonitoring()
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "gear.circle.fill")
                    .foregroundColor(statusColor())
                Text("Dev")
                    .font(.system(size: 12))
            }
        }
    }

    private func statusColor() -> Color {
        switch monitor.overallStatus {
        case "🟢 Healthy":
            return .green
        case "🟠 Degraded":
            return .orange
        case "🔴 Failed":
            return .red
        default:
            return .gray
        }
    }

    private func formatLastUpdate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Last: \(formatter.string(from: date))"
    }

    private func startAll() {
        for service in monitor.services {
            monitor.start(service: service.service)
        }
    }

    private func stopAll() {
        for service in monitor.services {
            monitor.stop(service: service.service)
        }
    }
}
