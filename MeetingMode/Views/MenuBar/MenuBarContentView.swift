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
        VStack(alignment: .leading, spacing: 14) {
            header

            if presetStore.hasPresets {
                section(title: t("menubar.section.preset", "Preset")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker(t("menubar.section.preset", "Preset"), selection: selectedPresetBinding) {
                            ForEach(presetStore.presets) { preset in
                                Text(preset.name).tag(Optional(preset.id))
                            }
                        }
                        .labelsHidden()
                        .disabled(sessionRunner.isSessionActive)

                        HStack {
                            Button(t("menubar.button.new", "New")) {
                                openPresetCreator()
                            }
                            .disabled(sessionRunner.isSessionActive)

                            if let preset = presetStore.selectedPreset {
                                Button(t("menubar.button.edit", "Edit")) {
                                    openPresetEditor(preset)
                                }
                                .disabled(sessionRunner.isSessionActive)

                                Button(t("menubar.button.delete", "Delete"), role: .destructive) {
                                    presetPendingDeletion = preset
                                }
                                .disabled(sessionRunner.isSessionActive)
                            }
                        }
                        .controlSize(.small)
                    }
                }

                section(title: sessionSectionTitle) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(summaryTitle)
                            .font(.subheadline.weight(.semibold))

                        Text(summaryLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let detailLine {
                            Text(detailLine)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                section(title: t("menubar.section.actions", "Actions")) {
                    HStack {
                        if !sessionRunner.isSessionActive,
                           let preset = presetStore.selectedPreset {
                            Button(t("menubar.button.start", "Start Session")) {
                                startSession()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!preset.hasStartableActions)
                        }

                        Spacer()

                        Button(t("menubar.button.restore", "Restore Session")) {
                            restoreSession()
                        }
                        .disabled(!sessionRunner.canRestoreSession)
                    }
                }
            } else {
                section(title: t("menubar.section.preset", "Preset")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(t("menubar.empty.no_presets", "No presets yet"))
                            .font(.subheadline.weight(.semibold))

                        Button(t("menubar.button.new_preset", "New Preset")) {
                            openPresetCreator()
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button(t("menubar.button.settings", "Settings…")) {
                    openSettings()
                }

                Spacer()

                Button(t("menubar.button.quit", "Quit")) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .controlSize(.small)
        }
        .padding(14)
        .frame(width: 292)
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Meeting Mode")
                    .font(.headline)

                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(
                title: statusTitle,
                tint: statusTint
            )
        }
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

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
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
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
