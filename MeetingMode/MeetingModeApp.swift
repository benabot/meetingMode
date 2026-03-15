import SwiftUI

@main
struct MeetingModeApp: App {
    @StateObject private var presetStore: PresetStore
    @StateObject private var permissionService: PermissionService
    @StateObject private var sessionRunner: SessionRunner

    init() {
        let presetStore = PresetStore()
        let overlayService = OverlayService()
        let appLauncherService = AppLauncherService()
        let restoreService = RestoreService(
            overlayService: overlayService,
            appLauncherService: appLauncherService
        )
        let permissionService = PermissionService()

        _presetStore = StateObject(wrappedValue: presetStore)
        _permissionService = StateObject(wrappedValue: permissionService)
        _sessionRunner = StateObject(
            wrappedValue: SessionRunner(
                appLauncherService: appLauncherService,
                overlayService: overlayService,
                restoreService: restoreService
            )
        )
    }

    var body: some Scene {
        MenuBarExtra(
            "Meeting Mode",
            systemImage: sessionRunner.isSessionActive ? "record.circle.fill" : "record.circle"
        ) {
            MenuBarContentView(
                presetStore: presetStore,
                sessionRunner: sessionRunner,
                permissionService: permissionService
            )
        }
        // Keep the window style for now: the content is a compact SwiftUI panel,
        // not a pure menu item list.
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(permissionService: permissionService)
        }
    }
}
