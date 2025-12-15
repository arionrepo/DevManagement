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
            HStack {
                // Small status circle
                Circle()
                    .fill(healthColor())
                    .frame(width: 10, height: 10)

                // Service name and status
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.headline)
                    Text(item.statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Technical details (right-aligned)
                VStack(alignment: .trailing, spacing: 2) {
                    if let endpoint = item.endpoint {
                        Text(endpoint)
                            .font(.caption)
                    }
                    if let latency = item.latency_ms, latency > 0 {
                        Text("\(latency) ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let uptime = item.uptime {
                        Text("up \(uptime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 8)

            // Bottom row: control buttons
            HStack(spacing: 6) {
                Button("Start") { onStart() }
                    .disabled(item.isRunning)
                Button("Stop") { onStop() }
                    .disabled(!item.isRunning)
                Button("Restart") { onRestart() }
                Button("Logs") { onLogs() }
                Spacer()  // Push buttons to left
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .padding(.leading, 18)
        }

        Divider()
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
}
