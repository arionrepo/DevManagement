import SwiftUI
import DevManagementCore

/// Individual service row component for the menu bar dropdown
struct ServiceRowView: View {
    let item: ServiceStatusItem
    let onRestart: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Text(item.icon)
                .font(.system(size: 16))
                .frame(width: 24, alignment: .center)

            // Service info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.system(.body, design: .default))
                    .fontWeight(.medium)
                Text(item.statusDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Restart button
            Button(action: onRestart) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .help("Restart \(item.displayName)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
