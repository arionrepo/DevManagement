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
                // Status indicator with outline and service icon
                ZStack {
                    Circle()
                        .fill(healthColor())
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.6))

                    Text(item.service.icon)
                        .font(.system(size: 9))
                        .offset(y: 0.5)
                }
                .frame(width: 18, height: 18)

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
                    if let endpoint = item.endpoint {
                        Text(endpoint)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    if let latency = item.latency_ms, latency > 0 {
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

            // Bottom row: control buttons with bordered style
            HStack(spacing: 6) {
                Button("Start", action: onStart)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .opacity(item.isRunning ? 0.35 : 1.0)
                    .controlSize(.small)

                Button("Stop", action: onStop)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .opacity(!item.isRunning ? 0.35 : 1.0)
                    .controlSize(.small)

                Button("Restart", action: onRestart)
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.small)

                Button("Logs", action: onLogs)
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .controlSize(.small)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }

        Divider().overlay(Color.primary.opacity(0.08))
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
