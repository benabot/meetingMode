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

            Picker("Preset", selection: $presetStore.selectedPresetID) {
                ForEach(presetStore.presets) { preset in
                    Text(preset.name).tag(Optional(preset.id))
                }
            }
            .labelsHidden()

            if let preset = presetStore.selectedPreset {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(preset.appsToLaunch.count) apps planned", systemImage: "app.connected.to.app.below.fill")
                    Label("\(preset.checklistItems.count) checklist items", systemImage: "checklist")
                    Label(
                        preset.showsOverlay ? "Overlay stub enabled" : "Overlay disabled",
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
        .onAppear {
            permissionService.refreshStatuses()
        }
    }

    private var statusText: String {
        if let snapshot = sessionRunner.activeSnapshot {
            return "Active preset: \(snapshot.presetName)"
        }

        return sessionRunner.lastActionDescription
    }
}

#Preview {
    MenuBarContentView(
        presetStore: PresetStore(),
        sessionRunner: SessionRunner(
            appLauncherService: AppLauncherService(),
            overlayService: OverlayService(),
            restoreService: RestoreService(
                overlayService: OverlayService(),
                appLauncherService: AppLauncherService()
            )
        ),
        permissionService: PermissionService()
    )
}
