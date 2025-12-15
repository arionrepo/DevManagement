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
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { monitor.updateStatus() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .controlSize(.small)
                        .help("Refresh service status")
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }

                Divider()

                // MARK: - Services List
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<monitor.services.count, id: \.self) { index in
                            let item = monitor.services[index]
                            ServiceRowView(
                                item: item,
                                onStart: { monitor.start(service: item.service) },
                                onStop: { monitor.stop(service: item.service) },
                                onRestart: { monitor.restart(service: item.service) },
                                onLogs: { openLogs(for: item.service) }
                            )
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                }
                .frame(height: 280)

                Divider()

                // MARK: - Action Buttons
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: { startAll() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("Start All")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(6)

                        Button(action: { stopAll() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("Stop All")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(6)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }

                Divider()

                // MARK: - Footer
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Overall Status")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(monitor.overallStatus)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Updated")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(formatLastUpdate(monitor.lastUpdate))
                                .font(.system(size: 12, weight: .medium))
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    HStack(spacing: 6) {
                        Spacer()
                        Button(action: { NSApplication.shared.terminate(nil) }) {
                            Text("Quit")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                    }
                }
            }
            .frame(width: 520)
            .background(.thickMaterial)
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

    private func openLogs(for service: Service) {
        // Determine log path based on service type
        var logPath: String? = nil

        switch service.id {
        case "colima":
            // Colima logs are in ~/.colima
            let colimaDir = NSHomeDirectory() + "/.colima"
            if FileManager.default.fileExists(atPath: colimaDir) {
                logPath = colimaDir
            }

        case "supabase":
            // Supabase logs in the configured log directory
            logPath = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs"

        case "python-backend":
            // Python backend logs
            logPath = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs"

        case "admin-ui":
            // Admin UI logs
            logPath = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs"

        case "customer-ui":
            // Customer UI logs
            logPath = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs"

        default:
            // Default to general logs directory
            logPath = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs"
        }

        // Open the log directory with default application (Finder)
        if let logPath = logPath, FileManager.default.fileExists(atPath: logPath) {
            let url = URL(fileURLWithPath: logPath)
            NSWorkspace.shared.open(url)
            print("📋 Opened logs for \(service.displayName): \(logPath)")
        } else {
            print("⚠️  Log directory not found for \(service.displayName)")
        }
    }
}
