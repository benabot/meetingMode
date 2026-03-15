import Combine
import Foundation

enum SessionPhase: String {
    case inactive = "Inactive"
    case active = "Active"
    case restored = "Restored"
}

@MainActor
final class SessionRunner: ObservableObject {
    @Published private(set) var activeSnapshot: SessionSnapshot?
    @Published private(set) var sessionPhase: SessionPhase = .inactive
    @Published private(set) var lastActionDescription = "Session inactive"

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

    var canStartSession: Bool {
        activeSnapshot == nil
    }

    var canRestoreSession: Bool {
        activeSnapshot != nil
    }

    func start(with preset: Preset) {
        guard activeSnapshot == nil else {
            lastActionDescription = "Restore the current session before starting another one"
            return
        }

        guard preset.hasStartableActions else {
            sessionPhase = .inactive
            lastActionDescription = "Add an app, URL, file, or clean screen before starting"
            return
        }

        let launchResult = appLauncherService.openItems(for: preset)
        let overlayWasShown = preset.showsOverlay ? overlayService.showOverlay() : false

        let appliedActionCount = launchResult.launchedApplications.count
            + launchResult.openedURLs.count
            + launchResult.openedFiles.count
            + (overlayWasShown ? 1 : 0)

        guard appliedActionCount > 0 else {
            sessionPhase = .inactive

            if launchResult.failureCount > 0 || preset.showsOverlay {
                lastActionDescription = "Nothing was opened. Check the preset items and clean screen."
            } else {
                lastActionDescription = "Add an app, URL, file, or clean screen before starting"
            }

            return
        }

        activeSnapshot = SessionSnapshot(
            id: UUID(),
            presetID: preset.id,
            presetName: preset.name,
            startedAt: Date(),
            launchedApplications: launchResult.launchedApplications,
            launchedApplicationBundleIdentifiers: launchResult.launchedApplicationBundleIdentifiers,
            openedURLs: launchResult.openedURLs,
            openedFiles: launchResult.openedFiles,
            overlayWasShown: overlayWasShown
        )
        sessionPhase = .active

        var statusIssues: [String] = []
        if launchResult.failureCount > 0 {
            statusIssues.append("\(launchResult.failureCount) items could not be opened")
        }
        if preset.showsOverlay && !overlayWasShown {
            statusIssues.append("clean screen unavailable")
        }

        if statusIssues.isEmpty {
            lastActionDescription = "Session active"
        } else {
            lastActionDescription = "Session active - \(statusIssues.joined(separator: ", "))"
        }
    }

    func restoreCurrentSession() {
        guard let activeSnapshot else { return }

        let restoreResult = restoreService.restore(from: activeSnapshot)
        self.activeSnapshot = nil
        sessionPhase = .restored

        var restoredItems: [String] = []

        if restoreResult.hidOverlay {
            restoredItems.append("clean screen hidden")
        }

        if restoreResult.closedApplicationsCount > 0 {
            let label = restoreResult.closedApplicationsCount == 1 ? "app" : "apps"
            restoredItems.append("\(restoreResult.closedApplicationsCount) launched \(label) closed")
        }

        if restoreResult.stillRunningApplicationsCount > 0 {
            let label = restoreResult.stillRunningApplicationsCount == 1 ? "app may still be open" : "apps may still be open"
            restoredItems.append("\(restoreResult.stillRunningApplicationsCount) launched \(label)")
        }

        if restoredItems.isEmpty {
            lastActionDescription = "Session restored"
        } else {
            lastActionDescription = "Session restored - \(restoredItems.joined(separator: ", "))"
        }
    }
}
