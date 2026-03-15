import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var presetStore: PresetStore
    @ObservedObject var sessionRunner: SessionRunner
    @ObservedObject var permissionService: PermissionService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meeting Mode")
                    .font(.headline)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if presetStore.hasPresets {
                Picker("Preset", selection: $presetStore.selectedPresetID) {
                    ForEach(presetStore.presets) { preset in
                        Text(preset.name).tag(Optional(preset.id))
                    }
                }
                .labelsHidden()
            }

            if let preset = presetStore.selectedPreset {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(preset.appsToLaunch.count) apps planned", systemImage: "app.connected.to.app.below.fill")
                    Label("\(preset.checklistItems.count) checklist items", systemImage: "checklist")
                    Label(
                        preset.showsOverlay ? "Clean screen enabled" : "Clean screen off",
                        systemImage: preset.showsOverlay ? "rectangle.on.rectangle" : "rectangle.slash"
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider()

                Button("Start Session") {
                    sessionRunner.start(with: preset)
                }
                .disabled(sessionRunner.isSessionActive)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No presets yet")
                        .font(.subheadline)

                    Text("A preset list will appear here once local editing is added.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Restore Session") {
                sessionRunner.restoreCurrentSession()
            }
            .disabled(!sessionRunner.isSessionActive)

            Divider()

            HStack {
                SettingsLink {
                    Text("Settings…")
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }

            Text(permissionService.shortSummary)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 300)
    }

    private var statusText: String {
        if let snapshot = sessionRunner.activeSnapshot {
            return "Active preset: \(snapshot.presetName)"
        }

        if !presetStore.hasPresets {
            return "No presets available"
        }

        return sessionRunner.lastActionDescription
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
    let restoreService = RestoreService(
        overlayService: overlayService,
        appLauncherService: appLauncherService
    )
    let presets = presets ?? [
        Preset(
            id: UUID(uuidString: "0E9D6B47-9348-4E28-A2A7-225C5F611001") ?? UUID(),
            name: "Client Call",
            iconSystemName: "person.2.fill",
            appsToLaunch: ["Calendar", "Notes", "Safari"],
            checklistItems: [
                ChecklistItem(title: "Open call brief"),
                ChecklistItem(title: "Check microphone"),
                ChecklistItem(title: "Close private tabs", isRequired: false),
            ],
            showsOverlay: true
        ),
        Preset(
            id: UUID(uuidString: "0E9D6B47-9348-4E28-A2A7-225C5F611002") ?? UUID(),
            name: "Product Demo",
            iconSystemName: "play.rectangle.fill",
            appsToLaunch: ["Xcode", "Safari", "Keynote"],
            checklistItems: [
                ChecklistItem(title: "Build latest demo"),
                ChecklistItem(title: "Prepare fallback browser tab"),
            ],
            showsOverlay: false
        ),
    ]

    return MenuBarContentView(
        presetStore: PresetStore(presets: presets),
        sessionRunner: SessionRunner(
            appLauncherService: appLauncherService,
            overlayService: overlayService,
            restoreService: restoreService
        ),
        permissionService: PermissionService()
    )
}
