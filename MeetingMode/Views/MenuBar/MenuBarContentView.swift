import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var presetStore: PresetStore
    @ObservedObject var sessionRunner: SessionRunner
    @ObservedObject var permissionService: PermissionService
    let openSettings: () -> Void
    let restoreSession: () -> Void

    @State private var isPresentingPresetEditor = false
    @State private var presetEditorMode: PresetEditorView.Mode = .create
    @State private var presetToEdit: Preset?
    @State private var presetEditorPresentationID = UUID()
    @State private var presetPendingDeletion: Preset?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if presetStore.hasPresets {
                section(title: "Preset") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Preset", selection: selectedPresetBinding) {
                            ForEach(presetStore.presets) { preset in
                                Text(preset.name).tag(Optional(preset.id))
                            }
                        }
                        .labelsHidden()
                        .disabled(sessionRunner.isSessionActive)

                        HStack {
                            Button("New") {
                                presentPresetEditor(mode: .create)
                            }
                            .disabled(sessionRunner.isSessionActive)

                            if let preset = presetStore.selectedPreset {
                                Button("Edit") {
                                    presentPresetEditor(mode: .edit, preset: preset)
                                }
                                .disabled(sessionRunner.isSessionActive)

                                Button("Delete", role: .destructive) {
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

                section(title: "Actions") {
                    HStack {
                        if !sessionRunner.isSessionActive,
                           let preset = presetStore.selectedPreset {
                            Button("Start Session") {
                                sessionRunner.start(with: preset)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!preset.hasStartableActions)
                        }

                        Spacer()

                        Button("Restore Session") {
                            restoreSession()
                        }
                        .disabled(!sessionRunner.canRestoreSession)
                    }
                }
            } else {
                section(title: "Preset") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No presets yet")
                            .font(.subheadline.weight(.semibold))

                        Button("New Preset") {
                            presentPresetEditor(mode: .create)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button("Settings…") {
                    openSettings()
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .controlSize(.small)
        }
        .padding(14)
        .frame(width: 292)
        .sheet(isPresented: $isPresentingPresetEditor) {
            PresetEditorView(
                mode: presetEditorMode,
                preset: presetToEdit
            ) { preset in
                switch presetEditorMode {
                case .create:
                    presetStore.addPreset(preset)
                case .edit:
                    presetStore.updatePreset(preset)
                }
            }
            .id(presetEditorPresentationID)
        }
        .alert(
            "Delete preset?",
            isPresented: isPresentingDeleteAlert,
            presenting: presetPendingDeletion
        ) { preset in
            Button("Delete", role: .destructive) {
                presetStore.deletePreset(preset)
                presetPendingDeletion = nil
            }

            Button("Cancel", role: .cancel) {
                presetPendingDeletion = nil
            }
        } message: { preset in
            Text("“\(preset.name)” will be removed from local storage.")
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

        return "No preset selected"
    }

    private var statusTitle: String {
        if !presetStore.hasPresets {
            return "Empty"
        }

        switch sessionRunner.sessionPhase {
        case .inactive:
            return "Ready"
        case .active:
            return "Active"
        case .restored:
            return "Restored"
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

        return "No preset selected"
    }

    private var summaryLine: String {
        if let snapshot = sessionRunner.activeSnapshot {
            let items = [
                countLabel(snapshot.launchedApplications.count, singular: "app opened", plural: "apps opened"),
                countLabel(snapshot.hiddenApplicationCount, singular: "app hidden", plural: "apps hidden"),
                countLabel(snapshot.openedURLs.count, singular: "link opened", plural: "links opened"),
                countLabel(snapshot.openedFiles.count, singular: "file opened", plural: "files opened"),
                snapshot.overlayWasShown ? "clean screen visible" : nil,
            ]

            return joinedSummary(items) ?? "No tracked action"
        }

        if sessionRunner.sessionPhase == .restored {
            if sessionRunner.lastActionDescription.contains("checking hidden apps") {
                return "Checking hidden apps"
            }

            if sessionRunner.lastActionDescription.contains("may still be hidden") {
                return "Restore finished with limits"
            }

            return "Best effort restore finished"
        }

        guard let preset = presetStore.selectedPreset else {
            return "Create a preset to prepare your next session."
        }

        let items = [
            countLabel(preset.appsToLaunch.count, singular: "app planned", plural: "apps planned"),
            countLabel(preset.urlsToOpen.count, singular: "link planned", plural: "links planned"),
            countLabel(preset.filesToOpen.count, singular: "file planned", plural: "files planned"),
            preset.showsOverlay ? "clean screen on" : nil,
        ]

        return joinedSummary(items) ?? "No runnable action yet"
    }

    private var sessionSectionTitle: String {
        switch sessionRunner.sessionPhase {
        case .active:
            return "Session"
        case .restored:
            return "Restore"
        case .inactive:
            return "Plan"
        }
    }

    private var detailLine: String? {
        if let snapshot = sessionRunner.activeSnapshot {
            if snapshot.restorableApplicationCount > 0 {
                return "Restore tracks \(countLabel(snapshot.restorableApplicationCount, singular: "changed app", plural: "changed apps") ?? "0 changed apps")"
            }

            return actionDetail(from: sessionRunner.lastActionDescription)
        }

        if sessionRunner.sessionPhase == .restored,
           let restoredDetail = actionDetail(from: sessionRunner.lastActionDescription) {
            return restoredDetail
        }

        guard let preset = presetStore.selectedPreset else {
            return nil
        }

        if preset.checklistItems.isEmpty {
            return preset.hasStartableActions
                ? "Other visible apps may be hidden best effort."
                : "Add an app, link, file, or clean screen to enable Start Session."
        }

        let checklistLabel = countLabel(
            preset.checklistItems.count,
            singular: "checklist item",
            plural: "checklist items"
        ) ?? "0 checklist items"

        if preset.hasStartableActions {
            return "\(checklistLabel) - other visible apps may be hidden best effort."
        }

        return "\(checklistLabel) - add at least one runnable action."
    }

    private func actionDetail(from description: String) -> String? {
        switch description {
        case "Session inactive", "Session active", "Session restored":
            return nil
        default:
            return description
                .replacingOccurrences(of: "Session active - ", with: "")
                .replacingOccurrences(of: "Session restored - ", with: "")
        }
    }

    private func countLabel(_ count: Int, singular: String, plural: String) -> String? {
        guard count > 0 else {
            return nil
        }

        let label = count == 1 ? singular : plural
        return "\(count) \(label)"
    }

    private func joinedSummary(_ items: [String?]) -> String? {
        let values = items.compactMap { $0 }
        guard !values.isEmpty else {
            return nil
        }

        return values.joined(separator: " · ")
    }

    private func presentPresetEditor(mode: PresetEditorView.Mode, preset: Preset? = nil) {
        presetEditorMode = mode
        presetToEdit = preset
        presetEditorPresentationID = UUID()
        isPresentingPresetEditor = true
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
    let overlayService = OverlayService()
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
        openSettings: {},
        restoreSession: {}
    )
}
