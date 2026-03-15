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
    private let appVisibilityService: AppVisibilityService
    private let overlayService: OverlayService
    private let restoreService: RestoreService
    private var pendingHiddenApplicationCandidates: [HiddenApplicationSnapshot] = []
    private var visibilityConfirmationTask: Task<Void, Never>?
    private var restoreVisibilityTask: Task<Void, Never>?

    init(
        appLauncherService: AppLauncherService,
        appVisibilityService: AppVisibilityService,
        overlayService: OverlayService,
        restoreService: RestoreService
    ) {
        self.appLauncherService = appLauncherService
        self.appVisibilityService = appVisibilityService
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

    func startIfPossible(with preset: Preset?) {
        guard let preset else {
            sessionPhase = activeSnapshot == nil ? .inactive : sessionPhase
            lastActionDescription = "Select a preset before starting"
            return
        }

        start(with: preset)
    }

    func start(with preset: Preset) {
        visibilityConfirmationTask?.cancel()
        restoreVisibilityTask?.cancel()

        guard activeSnapshot == nil else {
            lastActionDescription = "Restore the current session before starting another one"
            return
        }

        guard preset.hasStartableActions else {
            pendingHiddenApplicationCandidates = []
            sessionPhase = .inactive
            lastActionDescription = "Add an app, link, file, or clean screen before starting"
            return
        }

        let launchResult = appLauncherService.openItems(for: preset)
        let visibilityResult = appVisibilityService.hideNonPresetVisibleApps(keepingVisibleFor: preset)
        pendingHiddenApplicationCandidates = visibilityResult.requestedApplications
        let overlayWasShown = preset.showsOverlay ? overlayService.showOverlay() : false

        let appliedActionCount = launchResult.launchedApplications.count
            + visibilityResult.requestedApplicationCount
            + launchResult.openedURLs.count
            + launchResult.openedFiles.count
            + (overlayWasShown ? 1 : 0)

        guard appliedActionCount > 0 else {
            pendingHiddenApplicationCandidates = []
            sessionPhase = .inactive

            if launchResult.failureCount > 0 || preset.showsOverlay {
                lastActionDescription = "Nothing was opened. Check the preset items and clean screen."
            } else {
                lastActionDescription = "Add an app, link, file, or clean screen before starting"
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
            hiddenApplications: [],
            openedURLs: launchResult.openedURLs,
            openedFiles: launchResult.openedFiles,
            overlayWasShown: overlayWasShown
        )
        sessionPhase = .active
        updateActiveSessionDescription(
            requestedHiddenApplicationCount: visibilityResult.requestedApplicationCount,
            launchFailureCount: launchResult.failureCount,
            visibilityFailureCount: visibilityResult.failureCount,
            overlayWasRequested: preset.showsOverlay,
            overlayWasShown: overlayWasShown,
            isVisibilityPending: !pendingHiddenApplicationCandidates.isEmpty
        )
        scheduleVisibilityConfirmation(
            for: activeSnapshot?.id,
            requestedHiddenApplications: visibilityResult.requestedApplications,
            launchFailureCount: launchResult.failureCount,
            visibilityFailureCount: visibilityResult.failureCount,
            overlayWasRequested: preset.showsOverlay,
            overlayWasShown: overlayWasShown
        )
    }

    func restoreIfPossible() {
        guard activeSnapshot != nil else {
            if sessionPhase != .active {
                lastActionDescription = "No active session to restore"
            }
            return
        }

        restoreCurrentSession()
    }

    func restoreCurrentSession() {
        visibilityConfirmationTask?.cancel()
        restoreVisibilityTask?.cancel()

        guard var activeSnapshot else { return }

        if !pendingHiddenApplicationCandidates.isEmpty {
            let confirmation = appVisibilityService.confirmHiddenApplications(
                from: pendingHiddenApplicationCandidates,
                timeout: 1.0
            )
            activeSnapshot.hiddenApplications = mergedHiddenApplications(
                activeSnapshot.hiddenApplications,
                confirmation.hiddenApplications
            )
            pendingHiddenApplicationCandidates = []
        }

        let restoreResult = restoreService.restore(from: activeSnapshot)
        self.activeSnapshot = nil
        pendingHiddenApplicationCandidates = []
        sessionPhase = .restored
        updateRestoreDescription(
            with: restoreResult,
            revealedApplicationsCount: 0,
            stillHiddenApplicationsCount: 0,
            isVisibilityPending: !restoreResult.requestedVisibleApplications.isEmpty
        )
        scheduleRestoreVisibilityConfirmation(
            requestedVisibleApplications: restoreResult.requestedVisibleApplications,
            restoreResult: restoreResult
        )
    }

    private func scheduleVisibilityConfirmation(
        for sessionID: UUID?,
        requestedHiddenApplications: [HiddenApplicationSnapshot],
        launchFailureCount: Int,
        visibilityFailureCount: Int,
        overlayWasRequested: Bool,
        overlayWasShown: Bool
    ) {
        guard let sessionID,
              !requestedHiddenApplications.isEmpty else {
            return
        }

        visibilityConfirmationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else {
                return
            }
            self?.refreshHiddenApplications(
                for: sessionID,
                requestedHiddenApplications: requestedHiddenApplications,
                launchFailureCount: launchFailureCount,
                visibilityFailureCount: visibilityFailureCount,
                overlayWasRequested: overlayWasRequested,
                overlayWasShown: overlayWasShown
            )
            self?.visibilityConfirmationTask = nil
        }
    }

    private func refreshHiddenApplications(
        for sessionID: UUID,
        requestedHiddenApplications: [HiddenApplicationSnapshot],
        launchFailureCount: Int,
        visibilityFailureCount: Int,
        overlayWasRequested: Bool,
        overlayWasShown: Bool
    ) {
        guard var activeSnapshot,
              activeSnapshot.id == sessionID else {
            return
        }

        let confirmation = appVisibilityService.confirmHiddenApplications(
            from: requestedHiddenApplications,
            timeout: 1.0
        )
        activeSnapshot.hiddenApplications = mergedHiddenApplications(
            activeSnapshot.hiddenApplications,
            confirmation.hiddenApplications
        )
        self.activeSnapshot = activeSnapshot
        pendingHiddenApplicationCandidates = confirmation.stillVisibleApplications

        updateActiveSessionDescription(
            requestedHiddenApplicationCount: requestedHiddenApplications.count,
            launchFailureCount: launchFailureCount,
            visibilityFailureCount: visibilityFailureCount,
            overlayWasRequested: overlayWasRequested,
            overlayWasShown: overlayWasShown,
            isVisibilityPending: !pendingHiddenApplicationCandidates.isEmpty
        )
    }

    private func updateActiveSessionDescription(
        requestedHiddenApplicationCount: Int,
        launchFailureCount: Int,
        visibilityFailureCount: Int,
        overlayWasRequested: Bool,
        overlayWasShown: Bool,
        isVisibilityPending: Bool
    ) {
        let confirmedHiddenApplicationCount = activeSnapshot?.hiddenApplicationCount ?? 0
        let unresolvedHiddenApplicationCount = max(
            requestedHiddenApplicationCount - confirmedHiddenApplicationCount,
            0
        )
        var statusNotes: [String] = []

        if confirmedHiddenApplicationCount > 0 {
            let label = confirmedHiddenApplicationCount == 1 ? "app hidden" : "apps hidden"
            statusNotes.append("\(confirmedHiddenApplicationCount) \(label)")
        }

        if isVisibilityPending && requestedHiddenApplicationCount > 0 {
            statusNotes.append("checking app visibility")
        } else if unresolvedHiddenApplicationCount > 0 {
            let label = unresolvedHiddenApplicationCount == 1 ? "app stayed visible" : "apps stayed visible"
            statusNotes.append("\(unresolvedHiddenApplicationCount) \(label)")
        }

        if launchFailureCount > 0 {
            statusNotes.append("\(launchFailureCount) items could not be opened")
        }

        if visibilityFailureCount > 0 {
            let label = visibilityFailureCount == 1 ? "app skipped" : "apps skipped"
            statusNotes.append("\(visibilityFailureCount) \(label)")
        }

        if overlayWasRequested && !overlayWasShown {
            statusNotes.append("clean screen unavailable")
        }

        if statusNotes.isEmpty {
            lastActionDescription = "Session active"
        } else {
            lastActionDescription = "Session active - \(statusNotes.joined(separator: ", "))"
        }
    }

    private func scheduleRestoreVisibilityConfirmation(
        requestedVisibleApplications: [HiddenApplicationSnapshot],
        restoreResult: RestoreExecutionResult
    ) {
        guard !requestedVisibleApplications.isEmpty else {
            return
        }

        restoreVisibilityTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self,
                  !Task.isCancelled,
                  self.sessionPhase == .restored,
                  self.activeSnapshot == nil else {
                return
            }

            var confirmation = self.appVisibilityService.confirmVisibleApplications(
                from: requestedVisibleApplications,
                timeout: 0.4
            )
            var revealedApplications = confirmation.revealedApplications
            var stillHiddenApplications = confirmation.stillHiddenApplications

            if !stillHiddenApplications.isEmpty {
                let fallbackCandidates = self.appVisibilityService.requestOpenFallbacks(
                    for: stillHiddenApplications
                )

                if !fallbackCandidates.isEmpty {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    guard !Task.isCancelled else {
                        return
                    }

                    confirmation = self.appVisibilityService.confirmVisibleApplications(
                        from: fallbackCandidates,
                        timeout: 0.4
                    )
                    revealedApplications = self.mergedHiddenApplications(
                        revealedApplications,
                        confirmation.revealedApplications
                    )
                    stillHiddenApplications = confirmation.stillHiddenApplications
                }
            }

            self.updateRestoreDescription(
                with: restoreResult,
                revealedApplicationsCount: revealedApplications.count,
                stillHiddenApplicationsCount: stillHiddenApplications.count,
                isVisibilityPending: false
            )
            self.restoreVisibilityTask = nil
        }
    }

    private func updateRestoreDescription(
        with restoreResult: RestoreExecutionResult,
        revealedApplicationsCount: Int,
        stillHiddenApplicationsCount: Int,
        isVisibilityPending: Bool
    ) {
        var restoredItems: [String] = []

        if restoreResult.hidOverlay {
            restoredItems.append("clean screen hidden")
        }

        if isVisibilityPending {
            restoredItems.append("checking hidden apps")
        } else {
            if revealedApplicationsCount > 0 {
                let label = revealedApplicationsCount == 1 ? "hidden app shown again" : "hidden apps shown again"
                restoredItems.append("\(revealedApplicationsCount) \(label)")
            }

            if stillHiddenApplicationsCount > 0 {
                let label = stillHiddenApplicationsCount == 1 ? "hidden app may still be hidden" : "hidden apps may still be hidden"
                restoredItems.append("\(stillHiddenApplicationsCount) \(label)")
            }
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

    private func mergedHiddenApplications(
        _ lhs: [HiddenApplicationSnapshot],
        _ rhs: [HiddenApplicationSnapshot]
    ) -> [HiddenApplicationSnapshot] {
        Array(Set(lhs).union(rhs))
            .sorted { left, right in
                if left.localizedName == right.localizedName {
                    return left.processIdentifier < right.processIdentifier
                }

                return left.localizedName < right.localizedName
            }
    }
}
