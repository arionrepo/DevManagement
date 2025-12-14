import SwiftUI
import DevManagementCore

/// Individual service row component for the menu bar dropdown
struct ServiceRowView: View {
    let item: ServiceStatusItem
    let onRestart: () -> Void

    var backgroundColor: Color {
        switch item.icon {
        case "🟢":
            return Color(nsColor: NSColor(red: 0.95, green: 1.0, blue: 0.95, alpha: 1.0))
        case "🟠":
            return Color(nsColor: NSColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0))
        case "🔴":
            return Color(nsColor: NSColor(red: 1.0, green: 0.93, blue: 0.93, alpha: 1.0))
        default:
            return Color(nsColor: .controlBackgroundColor)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Large status icon
            Text(item.icon)
                .font(.system(size: 20))
                .frame(width: 28, alignment: .center)

            // Service info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.system(.body, design: .default))
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(item.statusDescription)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Restart button
            Button(action: onRestart) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("Restart \(item.displayName)")
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }
}
