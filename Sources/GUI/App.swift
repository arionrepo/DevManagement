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
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("⚙️ Dev Services")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { monitor.updateStatus() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderless)
                        .help("Refresh service status")
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                }
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // MARK: - Services List
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(0..<monitor.services.count, id: \.self) { index in
                            let item = monitor.services[index]
                            ServiceRowView(item: item) {
                                monitor.restart(service: item.service)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                }
                .frame(height: 220)

                Divider()

                // MARK: - Action Buttons
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Button(action: { startAll() }) {
                            Label("Start All", systemImage: "play.fill")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { stopAll() }) {
                            Label("Stop All", systemImage: "stop.fill")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                Divider()

                // MARK: - Footer
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Overall Status")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(monitor.overallStatus)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Updated")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(formatLastUpdate(monitor.lastUpdate))
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                    HStack(spacing: 6) {
                        Spacer()
                        Button(action: { NSApplication.shared.terminate(nil) }) {
                            Text("Quit")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
            }
            .frame(width: 360)
            .onAppear {
                monitor.startMonitoring()
            }
            .onDisappear {
                monitor.stopMonitoring()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "gear.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(statusColor())
                Text("Dev")
                    .font(.system(size: 11, weight: .semibold))
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
