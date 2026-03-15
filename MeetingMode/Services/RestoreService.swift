import Foundation

struct RestoreExecutionResult {
    var hidOverlay = false
    var closedApplicationsCount = 0
    var stillRunningApplicationsCount = 0
}

@MainActor
final class RestoreService {
    private let overlayService: OverlayService
    private let appLauncherService: AppLauncherService

    init(overlayService: OverlayService, appLauncherService: AppLauncherService) {
        self.overlayService = overlayService
        self.appLauncherService = appLauncherService
    }

    func restore(from snapshot: SessionSnapshot) -> RestoreExecutionResult {
        var result = RestoreExecutionResult()

        if snapshot.overlayWasShown {
            result.hidOverlay = overlayService.hideOverlay()
        }

        let applicationRestoreResult = appLauncherService.restoreApplications(from: snapshot)
        result.closedApplicationsCount = applicationRestoreResult.closedApplicationsCount
        result.stillRunningApplicationsCount = applicationRestoreResult.stillRunningApplicationsCount
        return result
    }
}
