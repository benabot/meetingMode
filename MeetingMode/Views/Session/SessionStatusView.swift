import SwiftUI

struct SessionStatusView: View {
    let phase: SessionPhase
    let activePresetName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(phase.rawValue, systemImage: iconSystemName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tintColor)

            Text(detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var detailText: String {
        switch phase {
        case .inactive:
            return "Ready to start a preset."
        case .active:
            if let activePresetName {
                return "Only one session can be active at a time. Current preset: \(activePresetName). Restore only tracks Meeting Mode changes."
            }

            return "Only one session can be active at a time. Restore only tracks Meeting Mode changes."
        case .restored:
            return "The previous session was restored on a best-effort basis. You can start a new one."
        }
    }

    private var iconSystemName: String {
        switch phase {
        case .inactive:
            return "pause.circle"
        case .active:
            return "record.circle.fill"
        case .restored:
            return "arrow.uturn.backward.circle"
        }
    }

    private var tintColor: Color {
        switch phase {
        case .inactive:
            return .secondary
        case .active:
            return .red
        case .restored:
            return .green
        }
    }

    private var backgroundColor: Color {
        switch phase {
        case .inactive:
            return Color.secondary.opacity(0.08)
        case .active:
            return Color.red.opacity(0.1)
        case .restored:
            return Color.green.opacity(0.1)
        }
    }
}

#Preview("Inactive") {
    SessionStatusView(phase: .inactive, activePresetName: nil)
        .padding()
        .frame(width: 320)
}

#Preview("Active") {
    SessionStatusView(phase: .active, activePresetName: "Client Call")
        .padding()
        .frame(width: 320)
}

#Preview("Restored") {
    SessionStatusView(phase: .restored, activePresetName: nil)
        .padding()
        .frame(width: 320)
}
