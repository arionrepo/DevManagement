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
            HStack(spacing: 8) {
                // Status indicator with outline and service icon
                ZStack {
                    Circle()
                        .fill(healthColor())
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))

                    Text(item.service.icon)
                        .font(.system(size: 8))
                        .offset(y: 0.5)
                }
                .frame(width: 16, height: 16)

                // Service name and status (left side)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.displayName)
                        .font(.headline)
                        .foregroundColor(Color(NSColor.labelColor))
                    Text(item.statusDescription)
                        .font(.caption)
                        .foregroundColor(Color(NSColor.labelColor))
                }

                Spacer()

                // Technical details (right-aligned)
                VStack(alignment: .trailing, spacing: 1) {
                    if let endpoint = item.endpoint {
                        Text(endpoint)
                            .font(.caption2)
                            .foregroundColor(Color(NSColor.labelColor))
                            .lineLimit(1)
                    }
                    if let latency = item.latency_ms, latency > 0 {
                        Text("\(latency) ms")
                            .font(.caption2)
                            .foregroundColor(Color(NSColor.labelColor))
                    }
                    if let uptime = item.uptime {
                        Text("up \(uptime)")
                            .font(.caption2)
                            .foregroundColor(Color(NSColor.labelColor))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            // Bottom row: control buttons with enhanced styling
            HStack(spacing: 4) {
                Button(action: onStart) {
                    Text("Start")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(item.isRunning ? 0.4 : 1.0))
                        .cornerRadius(4)
                }
                .disabled(item.isRunning)

                Button(action: onStop) {
                    Text("Stop")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(!item.isRunning ? 0.4 : 1.0))
                        .cornerRadius(4)
                }
                .disabled(!item.isRunning)

                Button(action: onRestart) {
                    Text("Restart")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .cornerRadius(4)
                }

                Button(action: onLogs) {
                    Text("Logs")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray)
                        .cornerRadius(4)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
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
