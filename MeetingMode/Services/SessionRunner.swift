import Combine
import Foundation

@MainActor
final class SessionRunner: ObservableObject {
    @Published private(set) var activeSnapshot: SessionSnapshot?
    @Published private(set) var lastActionDescription = "Idle"

    private let appLauncherService: AppLauncherService
    private let overlayService: OverlayService
    private let restoreService: RestoreService

    init(
        appLauncherService: AppLauncherService,
        overlayService: OverlayService,
        restoreService: RestoreService
    ) {
        self.appLauncherService = appLauncherService
        self.overlayService = overlayService
        self.restoreService = restoreService
    }

    var isSessionActive: Bool {
        activeSnapshot != nil
    }

    func start(with preset: Preset) {
        guard activeSnapshot == nil else { return }

        let launchedApplications = appLauncherService.launchApplications(for: preset)
        if preset.showsOverlay {
            overlayService.showOverlay()
        }

        activeSnapshot = SessionSnapshot(
            id: UUID(),
            presetID: preset.id,
            presetName: preset.name,
            startedAt: Date(),
            launchedApplications: launchedApplications,
            overlayWasShown: preset.showsOverlay
        )
        lastActionDescription = "Active session: \(preset.name)"
    }

    func restoreCurrentSession() {
        guard let activeSnapshot else { return }

        restoreService.restore(from: activeSnapshot)
        self.activeSnapshot = nil
        lastActionDescription = "Session restored"
    }
}
