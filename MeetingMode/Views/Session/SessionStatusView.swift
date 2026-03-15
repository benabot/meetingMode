import SwiftUI

struct SessionStatusView: View {
    @ObservedObject var appLanguageService: AppLanguageService
    let phase: SessionPhase
    let activePresetName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(phaseTitle, systemImage: iconSystemName)
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
            return t("session.status.inactive.detail", "Ready to start a preset.")
        case .active:
            if let activePresetName {
                return t(
                    "session.status.active.detail_with_preset",
                    "Only one session can be active at a time. Current preset: %@. Restore only tracks Meeting Mode changes.",
                    activePresetName
                )
            }

            return t(
                "session.status.active.detail",
                "Only one session can be active at a time. Restore only tracks Meeting Mode changes."
            )
        case .restored:
            return t(
                "session.status.restored.detail",
                "The previous session was restored on a best-effort basis. You can start a new one."
            )
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .inactive:
            return t("session.phase.inactive", "Inactive")
        case .active:
            return t("session.phase.active", "Active")
        case .restored:
            return t("session.phase.restored", "Restored")
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

    private func t(_ key: String, _ defaultValue: String, _ arguments: CVarArg...) -> String {
        appLanguageService.localized(key, defaultValue: defaultValue, arguments: arguments)
    }
}

#Preview("Inactive") {
    SessionStatusView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "SessionStatusPreviewLanguage1")),
        phase: .inactive,
        activePresetName: nil
    )
        .padding()
        .frame(width: 320)
}

#Preview("Active") {
    SessionStatusView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "SessionStatusPreviewLanguage2")),
        phase: .active,
        activePresetName: "Client Call"
    )
        .padding()
        .frame(width: 320)
}

#Preview("Restored") {
    SessionStatusView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "SessionStatusPreviewLanguage3")),
        phase: .restored,
        activePresetName: nil
    )
        .padding()
        .frame(width: 320)
}
