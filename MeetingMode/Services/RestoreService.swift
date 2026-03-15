import Foundation

@MainActor
final class RestoreService {
    private let overlayService: OverlayService
    private let appLauncherService: AppLauncherService

    init(overlayService: OverlayService, appLauncherService: AppLauncherService) {
        self.overlayService = overlayService
        self.appLauncherService = appLauncherService
    }

    func restore(from snapshot: SessionSnapshot) {
        if snapshot.overlayWasShown {
            overlayService.hideOverlay()
        }

        appLauncherService.restoreApplications(from: snapshot)
    }
}
