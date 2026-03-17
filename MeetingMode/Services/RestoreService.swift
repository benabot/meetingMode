import Foundation
import OSLog

struct RestoreExecutionResult {
    var hidOverlay = false
    var closedApplicationsCount = 0
    var stillRunningApplicationsCount = 0
    var requestedVisibleApplications: [HiddenApplicationSnapshot] = []
}

@MainActor
final class RestoreService: SessionRestoring {
    private let logger = Logger(subsystem: "fr.beabot.meetingmode", category: "Restore")
    private let overlayService: OverlayService
    private let appLauncherService: AppLauncherService
    private let appVisibilityService: AppVisibilityService

    init(
        overlayService: OverlayService,
        appLauncherService: AppLauncherService,
        appVisibilityService: AppVisibilityService
    ) {
        self.overlayService = overlayService
        self.appLauncherService = appLauncherService
        self.appVisibilityService = appVisibilityService
    }

    func restore(from snapshot: SessionSnapshot) -> RestoreExecutionResult {
        var result = RestoreExecutionResult()
        logger.notice("Restore start preset=\(snapshot.presetName, privacy: .public) hiddenApps=\(snapshot.hiddenApplicationCount, privacy: .public) launchedApps=\(snapshot.launchedApplicationBundleIdentifiers.count, privacy: .public)")

        if snapshot.overlayWasShown {
            result.hidOverlay = overlayService.hideOverlay()
            logger.notice("Restore overlay hidden=\(result.hidOverlay, privacy: .public)")
        }

        let applicationRestoreResult = appLauncherService.restoreApplications(from: snapshot)
        result.closedApplicationsCount = applicationRestoreResult.closedApplicationsCount
        result.stillRunningApplicationsCount = applicationRestoreResult.stillRunningApplicationsCount
        logger.notice("Restore launched apps closed=\(result.closedApplicationsCount, privacy: .public) stillRunning=\(result.stillRunningApplicationsCount, privacy: .public)")

        result.requestedVisibleApplications = appVisibilityService.beginVisibilityRestore(from: snapshot)
        logger.notice("Restore hidden apps requested=\(result.requestedVisibleApplications.count, privacy: .public)")
        return result
    }
}
