import SwiftUI
import DevManagementCore

/// Individual service row component for the menu bar dropdown - Information-dense layout
struct ServiceRowView: View {
    let item: ServiceStatusItem
    let onStart: () -> Void
    let onStop: () -> Void
    let onRestart: () -> Void
    let onLogs: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top row: status indicator, service info, technical details
            HStack(spacing: 10) {
                // Status indicator - colored circle only
                Circle()
                    .fill(healthColor())
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.12), radius: 1, y: 0.5)

                // Service name and status (left side)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(item.statusDescription)
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Technical details (right-aligned)
                VStack(alignment: .trailing, spacing: 1) {
                    if let cpus = item.cpus {
                        Text("\(cpus) CPU")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    } else if let endpoint = item.endpoint {
                        Text(endpoint)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    if let memory = item.memory_gb {
                        Text(String(format: "%.0f GB", memory))
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.9))
                    } else if let latency = item.latency_ms, latency > 0 {
                        Text("\(latency) ms")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                    if let uptime = item.uptime {
                        Text("up \(uptime)")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            // Bottom row: control buttons with custom fill style
            HStack(spacing: 6) {
                actionButton("Start", color: .green, disabled: item.isRunning, action: onStart)
                actionButton("Stop", color: .red, disabled: !item.isRunning, action: onStop)
                actionButton("Restart", color: .blue, disabled: false, action: onRestart)
                actionButton("Logs", color: .gray, disabled: false, action: onLogs)

                Spacer()

                // View scripts button - shows commands and allows copying/opening
                Menu {
                    if !item.service.commands.start.isEmpty {
                        Section("Start Command") {
                            Text(item.service.commands.start)
                                .font(.system(.caption, design: .monospaced))
                            Button(action: { copyToClipboard(item.service.commands.start) }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            if let scriptPath = extractScriptPath(item.service.commands.start) {
                                Button(action: { openInEditor(scriptPath) }) {
                                    Label("Open script: \(URL(fileURLWithPath: scriptPath).lastPathComponent)", systemImage: "pencil")
                                }
                            }
                        }
                    }
                    if !item.service.commands.stop.isEmpty {
                        Section("Stop Command") {
                            Text(item.service.commands.stop)
                                .font(.system(.caption, design: .monospaced))
                            Button(action: { copyToClipboard(item.service.commands.stop) }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            if let scriptPath = extractScriptPath(item.service.commands.stop) {
                                Button(action: { openInEditor(scriptPath) }) {
                                    Label("Open script: \(URL(fileURLWithPath: scriptPath).lastPathComponent)", systemImage: "pencil")
                                }
                            }
                        }
                    }
                    if !item.service.commands.restart.isEmpty {
                        Section("Restart Command") {
                            Text(item.service.commands.restart)
                                .font(.system(.caption, design: .monospaced))
                            Button(action: { copyToClipboard(item.service.commands.restart) }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            if let scriptPath = extractScriptPath(item.service.commands.restart) {
                                Button(action: { openInEditor(scriptPath) }) {
                                    Label("Open script: \(URL(fileURLWithPath: scriptPath).lastPathComponent)", systemImage: "pencil")
                                }
                            }
                        }
                    }
                    if let status = item.service.commands.status, !status.isEmpty {
                        Section("Status Command") {
                            Text(status)
                                .font(.system(.caption, design: .monospaced))
                            Button(action: { copyToClipboard(status) }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Scripts")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.7))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }

        Divider().overlay(Color.primary.opacity(0.08))
    }

    private func actionButton(_ title: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 70, height: 26)
                .background(disabled ? color.opacity(0.35) : color)
                .cornerRadius(6)
        }
        .disabled(disabled)
    }

    private func healthColor() -> Color {
        switch item.icon {
        case "🟢":
            return .green
        case "🟠":
            return .orange
        case "🔴":
            return .red
        default:
            return .gray
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func extractScriptPath(_ command: String) -> String? {
        // Parse command to find .sh file paths
        // Examples: "bash /path/to/script.sh" -> "/path/to/script.sh"
        // "colima start app" -> nil (no script file)
        let components = command.split(separator: " ")
        for component in components {
            let path = String(component)
            if path.hasSuffix(".sh") {
                return path
            }
        }
        return nil
    }

    private func openInEditor(_ path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
}
