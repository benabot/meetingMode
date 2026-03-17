import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var appLanguageService: AppLanguageService
    @ObservedObject var presetStore: PresetStore
    @ObservedObject var sessionRunner: SessionRunner
    @ObservedObject var permissionService: PermissionService
    let startSession: () -> Void
    let openPresetCreator: () -> Void
    let openPresetEditor: (Preset) -> Void
    let openSettings: () -> Void
    let restoreSession: () -> Void

    @State private var presetPendingDeletion: Preset?

    var body: some View {
        ZStack {
            MeetingModeWindowBackground()

            VStack(alignment: .leading, spacing: 11) {
                header

                if presetStore.hasPresets {
                    presetSection
                    sessionSection
                    actionsSection
                } else {
                    emptyPresetSection
                }

                footerBar
            }
            .padding(12)
        }
        .frame(width: 334)
        .alert(
            t("menubar.alert.delete_title", "Delete preset?"),
            isPresented: isPresentingDeleteAlert,
            presenting: presetPendingDeletion
        ) { preset in
            Button(t("menubar.button.delete", "Delete"), role: .destructive) {
                presetStore.deletePreset(preset)
                presetPendingDeletion = nil
            }

            Button(t("preset_editor.button.cancel", "Cancel"), role: .cancel) {
                presetPendingDeletion = nil
            }
        } message: { preset in
            Text(
                t(
                    "menubar.alert.delete_message",
                    "\"%@\" will be removed from local storage.",
                    preset.name
                )
            )
        }
    }

    private var header: some View {
        MeetingModeGlassCard(tone: statusTone, style: .hero, spacing: 10, contentPadding: 16) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(statusTint.opacity(0.12))
                    Circle()
                        .stroke(statusTint.opacity(0.24), lineWidth: 1)

                    Image(systemName: sessionRunner.isSessionActive ? "record.circle.fill" : "record.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(statusTint)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Meeting Mode")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MeetingModeTextPalette.primary)

                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(MeetingModeTextPalette.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                StatusBadge(title: statusTitle, tint: statusTint)
            }
        }
    }

    private var presetSection: some View {
        sectionCard(
            title: t("menubar.section.preset", "Preset"),
            symbol: "square.stack.3d.up",
            style: .section
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Picker(t("menubar.section.preset", "Preset"), selection: selectedPresetBinding) {
                    ForEach(presetStore.presets) { preset in
                        Text(preset.name).tag(Optional(preset.id))
                    }
                }
                .labelsHidden()
                .disabled(sessionRunner.isSessionActive)

                HStack(spacing: 8) {
                    Button(t("menubar.button.new", "New")) {
                        openPresetCreator()
                    }
                    .disabled(sessionRunner.isSessionActive)
                    .meetingModeActionButton(tone: .accent, role: .secondary)

                    if let preset = presetStore.selectedPreset {
                        Button(t("menubar.button.edit", "Edit")) {
                            openPresetEditor(preset)
                        }
                        .disabled(sessionRunner.isSessionActive)
                        .meetingModeActionButton(tone: .positive, role: .secondary)

                        Button(role: .destructive) {
                            presetPendingDeletion = preset
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(
                            sessionRunner.isSessionActive
                                ? MeetingModeTextPalette.disabled
                                : MeetingModeVisualTone.critical.tint
                        )
                        .disabled(sessionRunner.isSessionActive)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
            }
        }
    }

    private var sessionSection: some View {
        sectionCard(title: sessionSectionTitle, symbol: sessionSectionSymbol, tone: statusTone, style: .section) {
            VStack(alignment: .leading, spacing: 7) {
                Text(summaryTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MeetingModeTextPalette.primary)

                Text(summaryLine)
                    .font(.caption)
                    .foregroundStyle(MeetingModeTextPalette.secondary)

                if let detailLine {
                    Text(detailLine)
                        .font(.caption)
                        .foregroundStyle(MeetingModeTextPalette.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var actionsSection: some View {
        sectionCard(
            title: t("menubar.section.actions", "Actions"),
            symbol: "bolt.circle",
            tone: .accent,
            style: .action
        ) {
            VStack(spacing: 10) {
                if let preset = presetStore.selectedPreset {
                    Button {
                        startSession()
                    } label: {
                        Text(t("menubar.button.start", "Start Session"))
                            .lineLimit(1)
                            .minimumScaleFactor(1)
                    }
                    .disabled(sessionRunner.isSessionActive || !preset.hasStartableActions)
                    .meetingModeActionButton(tone: .accent, role: .primary)
                    .opacity(sessionRunner.isSessionActive ? 0.65 : 1)
                }

                Button {
                    restoreSession()
                } label: {
                    Text(t("menubar.button.restore", "Restore Session"))
                        .lineLimit(1)
                        .minimumScaleFactor(1)
                }
                .disabled(!sessionRunner.canRestoreSession)
                .meetingModeActionButton(
                    tone: sessionRunner.canRestoreSession ? .positive : .neutral,
                    role: .secondary
                )
                .opacity(sessionRunner.canRestoreSession ? 1 : 0.55)
            }
        }
    }

    private var emptyPresetSection: some View {
        sectionCard(
            title: t("menubar.section.preset", "Preset"),
            symbol: "tray",
            tone: .neutral,
            style: .section
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text(t("menubar.empty.no_presets", "No presets yet"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MeetingModeTextPalette.primary)

                Text(t("menubar.summary.create_preset", "Create a preset to prepare your next session."))
                    .font(.caption)
                    .foregroundStyle(MeetingModeTextPalette.secondary)

                Button(t("menubar.button.new_preset", "New Preset")) {
                    openPresetCreator()
                }
                .meetingModeActionButton(tone: .accent, role: .primary)
            }
        }
    }

    private var footerBar: some View {
        MeetingModeGlassCard(style: .footer, spacing: 0, contentPadding: 8) {
            HStack {
                Button(t("menubar.button.settings", "Settings…")) {
                    openSettings()
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(MeetingModeTextPalette.secondary)

                Spacer()

                Button(t("menubar.button.quit", "Quit")) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(MeetingModeTextPalette.muted)
            }
            .padding(.horizontal, 4)
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        symbol: String,
        tone: MeetingModeVisualTone = .neutral,
        style: MeetingModeGlassCardStyle = .section,
        @ViewBuilder content: () -> Content
    ) -> some View {
        MeetingModeGlassCard(tone: tone, style: style) {
            MeetingModeSectionHeader(title: title, symbol: symbol)
            content()
        }
    }

    private var selectedPresetBinding: Binding<Preset.ID?> {
        Binding(
            get: { presetStore.selectedPresetID },
            set: { presetStore.selectPreset($0) }
        )
    }

    private var isPresentingDeleteAlert: Binding<Bool> {
        Binding(
            get: { presetPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    presetPendingDeletion = nil
                }
            }
        )
    }

    private var headerSubtitle: String {
        if let snapshot = sessionRunner.activeSnapshot {
            return snapshot.presetName
        }

        if let preset = presetStore.selectedPreset {
            return preset.name
        }

        return t("menubar.empty.no_preset_selected", "No preset selected")
    }

    private var statusTitle: String {
        if !presetStore.hasPresets {
            return t("menubar.status.empty", "Empty")
        }

        switch sessionRunner.sessionPhase {
        case .inactive:
            return t("menubar.status.ready", "Ready")
        case .active:
            return t("menubar.status.active", "Active")
        case .restored:
            return t("menubar.status.restored", "Restored")
        }
    }

    private var statusTint: Color {
        if !presetStore.hasPresets {
            return .secondary
        }

        switch sessionRunner.sessionPhase {
        case .inactive:
            return .secondary
        case .active:
            return .red
        case .restored:
            return .green
        }
    }

    private var statusTone: MeetingModeVisualTone {
        if !presetStore.hasPresets {
            return .neutral
        }

        switch sessionRunner.sessionPhase {
        case .inactive:
            return .accent
        case .active:
            return .critical
        case .restored:
            return .positive
        }
    }

    private var summaryTitle: String {
        if let snapshot = sessionRunner.activeSnapshot {
            return snapshot.presetName
        }

        if let preset = presetStore.selectedPreset {
            return preset.name
        }

        return t("menubar.empty.no_preset_selected", "No preset selected")
    }

    private var summaryLine: String {
        if let snapshot = sessionRunner.activeSnapshot {
            let items = [
                countLabel(snapshot.launchedApplications.count, oneKey: "menubar.count.app_opened.one", otherKey: "menubar.count.app_opened.other", defaultOne: "app opened", defaultOther: "apps opened"),
                countLabel(snapshot.hiddenApplicationCount, oneKey: "menubar.count.app_hidden.one", otherKey: "menubar.count.app_hidden.other", defaultOne: "app hidden", defaultOther: "apps hidden"),
                countLabel(snapshot.openedURLs.count, oneKey: "menubar.count.link_opened.one", otherKey: "menubar.count.link_opened.other", defaultOne: "link opened", defaultOther: "links opened"),
                countLabel(snapshot.openedFiles.count, oneKey: "menubar.count.file_opened.one", otherKey: "menubar.count.file_opened.other", defaultOne: "file opened", defaultOther: "files opened"),
                snapshot.overlayWasShown ? t("menubar.clean_screen_on", "clean screen background on") : nil,
            ]

            return joinedSummary(items) ?? t("menubar.summary.no_tracked_action", "No tracked action")
        }

        if sessionRunner.sessionPhase == .restored {
            if sessionRunner.isCheckingHiddenApps {
                return t("menubar.summary.checking_hidden_apps", "Checking hidden apps")
            }

            if sessionRunner.restoreHasVisibilityLimit {
                return t("menubar.summary.restore_limited", "Restore finished with limits")
            }

            return t("menubar.summary.restore_finished", "Best effort restore finished")
        }

        guard let preset = presetStore.selectedPreset else {
            return t("menubar.summary.create_preset", "Create a preset to prepare your next session.")
        }

        let items = [
            countLabel(preset.appsToLaunch.count, oneKey: "menubar.count.app_planned.one", otherKey: "menubar.count.app_planned.other", defaultOne: "app planned", defaultOther: "apps planned"),
            countLabel(preset.urlsToOpen.count, oneKey: "menubar.count.link_planned.one", otherKey: "menubar.count.link_planned.other", defaultOne: "link planned", defaultOther: "links planned"),
            countLabel(preset.filesToOpen.count, oneKey: "menubar.count.file_planned.one", otherKey: "menubar.count.file_planned.other", defaultOne: "file planned", defaultOther: "files planned"),
            preset.showsOverlay ? t("menubar.clean_screen_on", "clean screen background on") : nil,
        ]

        return joinedSummary(items) ?? t("menubar.summary.no_runnable_action", "No runnable action yet")
    }

    private var sessionSectionTitle: String {
        switch sessionRunner.sessionPhase {
        case .active:
            return t("menubar.section.session", "Session")
        case .restored:
            return t("menubar.section.restore", "Restore")
        case .inactive:
            return t("menubar.section.plan", "Plan")
        }
    }

    private var sessionSectionSymbol: String {
        switch sessionRunner.sessionPhase {
        case .active:
            return "bolt.horizontal.circle"
        case .restored:
            return "arrow.uturn.backward.circle"
        case .inactive:
            return "list.bullet.rectangle"
        }
    }

    private var detailLine: String? {
        if let snapshot = sessionRunner.activeSnapshot {
            if snapshot.restorableApplicationCount > 0 {
                let trackedCount = countLabel(
                    snapshot.restorableApplicationCount,
                    oneKey: "menubar.count.changed_app.one",
                    otherKey: "menubar.count.changed_app.other",
                    defaultOne: "changed app",
                    defaultOther: "changed apps"
                ) ?? t("menubar.count.format", "%d %@", 0, t("menubar.count.changed_app.other", "changed apps"))

                return t("menubar.detail.restore_tracks", "Restore tracks %@", trackedCount)
            }

            return sessionRunner.lastActionDetail
        }

        if sessionRunner.sessionPhase == .restored,
           let restoredDetail = sessionRunner.lastActionDetail {
            return restoredDetail
        }

        guard let preset = presetStore.selectedPreset else {
            return nil
        }

        if preset.checklistItems.isEmpty {
            return preset.hasStartableActions
                ? t("menubar.detail.other_apps_may_hide", "Other visible apps may be hidden best effort.")
                : t("menubar.detail.enable_start", "Add an app, link, file, or clean screen to enable Start Session.")
        }

        let checklistLabel = countLabel(
            preset.checklistItems.count,
            oneKey: "menubar.count.checklist_item.one",
            otherKey: "menubar.count.checklist_item.other",
            defaultOne: "checklist item",
            defaultOther: "checklist items"
        ) ?? t("menubar.count.format", "%d %@", 0, t("menubar.count.checklist_item.other", "checklist items"))

        if preset.hasStartableActions {
            return t("menubar.detail.checklist_with_hide", "%@ - other visible apps may be hidden best effort.", checklistLabel)
        }

        return t("menubar.detail.checklist_needs_action", "%@ - add at least one runnable action.", checklistLabel)
    }

    private func countLabel(
        _ count: Int,
        oneKey: String,
        otherKey: String,
        defaultOne: String,
        defaultOther: String
    ) -> String? {
        guard count > 0 else {
            return nil
        }

        let label = t(
            count == 1 ? oneKey : otherKey,
            count == 1 ? defaultOne : defaultOther
        )
        return t("menubar.count.format", "%d %@", count, label)
    }

    private func joinedSummary(_ items: [String?]) -> String? {
        let values = items.compactMap { $0 }
        guard !values.isEmpty else {
            return nil
        }

        return values.joined(separator: " · ")
    }

    private func t(_ key: String, _ defaultValue: String, _ arguments: CVarArg...) -> String {
        appLanguageService.localized(key, defaultValue: defaultValue, arguments: arguments)
    }

}

private struct StatusBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(tint)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.14))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(tint.opacity(0.22), lineWidth: 1)
                    )
            )
    }
}

#Preview("Sample Presets") {
    previewMenuBarContentView()
}

#Preview("No Presets") {
    previewMenuBarContentView(presets: [])
}

@MainActor
private func previewMenuBarContentView(presets: [Preset]? = nil) -> some View {
    let appLanguageService = AppLanguageService(defaults: UserDefaults(suiteName: "MenuBarPreviewLanguage"))
    let overlayService = OverlayService(appLanguageService: appLanguageService)
    let appLauncherService = AppLauncherService()
    let appVisibilityService = AppVisibilityService()
    let restoreService = RestoreService(
        overlayService: overlayService,
        appLauncherService: appLauncherService,
        appVisibilityService: appVisibilityService
    )
    let presets = presets ?? [
        Preset(
            name: "Client Call",
            iconSystemName: "person.2.fill",
            appsToLaunch: [
                PresetApp(displayName: "Calendar", bundleIdentifier: "com.apple.iCal", bundlePath: "/System/Applications/Calendar.app"),
                PresetApp(displayName: "Notes", bundleIdentifier: "com.apple.Notes", bundlePath: "/System/Applications/Notes.app"),
                PresetApp(displayName: "Safari", bundleIdentifier: "com.apple.Safari", bundlePath: "/Applications/Safari.app"),
            ],
            urlsToOpen: ["https://meet.example.com/client-call"],
            filesToOpen: ["/Users/benoitabot/Documents/Client Brief.pdf"],
            checklistItems: [
                ChecklistItem(title: "Open call brief"),
                ChecklistItem(title: "Check microphone"),
                ChecklistItem(title: "Close private tabs", isRequired: false),
            ],
            showsOverlay: true
        ),
        Preset(
            name: "Product Demo",
            iconSystemName: "play.rectangle.fill",
            appsToLaunch: [
                PresetApp(displayName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", bundlePath: "/Applications/Xcode.app"),
                PresetApp(displayName: "Safari", bundleIdentifier: "com.apple.Safari", bundlePath: "/Applications/Safari.app"),
                PresetApp(displayName: "Keynote", bundleIdentifier: "com.apple.iWork.Keynote", bundlePath: "/Applications/Keynote.app"),
            ],
            urlsToOpen: ["https://staging.example.com/demo"],
            filesToOpen: ["/Users/benoitabot/Documents/Demo Notes.md"],
            checklistItems: [
                ChecklistItem(title: "Build latest demo"),
                ChecklistItem(title: "Prepare fallback browser tab"),
            ],
            showsOverlay: false
        ),
    ]

    return MenuBarContentView(
        appLanguageService: appLanguageService,
        presetStore: PresetStore(
            presets: presets,
            storageURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("meetingmode-preview-presets.json"),
            selectionDefaults: nil
        ),
        sessionRunner: SessionRunner(
            appLauncherService: appLauncherService,
            appVisibilityService: appVisibilityService,
            overlayService: overlayService,
            restoreService: restoreService
        ),
        permissionService: PermissionService(),
        startSession: {},
        openPresetCreator: {},
        openPresetEditor: { _ in },
        openSettings: {},
        restoreSession: {}
    )
}
