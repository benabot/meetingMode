import Combine
import Foundation

enum SessionPhase: String {
    case inactive = "Inactive"
    case active = "Active"
    case restored = "Restored"
}

enum SessionActionState: Equatable {
    case inactive
    case selectPresetBeforeStarting
    case restoreBeforeStartingAnother
    case addRunnableActionBeforeStarting
    case nothingOpened
    case noActiveSessionToRestore
    case active(ActiveSessionFeedback)
    case restored(RestoreSessionFeedback)
}

struct ActiveSessionFeedback: Equatable {
    var confirmedHiddenApplicationCount: Int
    var unresolvedHiddenApplicationCount: Int
    var launchFailureCount: Int
    var visibilityFailureCount: Int
    var overlayWasRequested: Bool
    var overlayWasShown: Bool
    var isVisibilityPending: Bool
}

struct RestoreSessionFeedback: Equatable {
    var hidOverlay: Bool
    var revealedApplicationsCount: Int
    var stillHiddenApplicationsCount: Int
    var closedApplicationsCount: Int
    var stillRunningApplicationsCount: Int
    var isVisibilityPending: Bool
}

@MainActor
final class SessionRunner: ObservableObject {
    @Published private(set) var activeSnapshot: SessionSnapshot?
    @Published private(set) var sessionPhase: SessionPhase = .inactive
    @Published private(set) var lastActionState: SessionActionState = .inactive

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

    var lastActionDescription: String {
        switch lastActionState {
        case .inactive:
            return L10n.string("session.notice.inactive", defaultValue: "Session inactive")
        case .selectPresetBeforeStarting:
            return L10n.string("session.notice.select_preset", defaultValue: "Select a preset before starting")
        case .restoreBeforeStartingAnother:
            return L10n.string(
                "session.notice.restore_before_start",
                defaultValue: "Restore the current session before starting another one"
            )
        case .addRunnableActionBeforeStarting:
            return L10n.string(
                "session.notice.add_runnable_action",
                defaultValue: "Add an app, link, file, or clean screen before starting"
            )
        case .nothingOpened:
            return L10n.string(
                "session.notice.nothing_opened",
                defaultValue: "Nothing was opened. Check the preset items and clean screen."
            )
        case .noActiveSessionToRestore:
            return L10n.string(
                "session.notice.no_active_session",
                defaultValue: "No active session to restore"
            )
        case .active(let feedback):
            guard let detail = localizedDetail(for: feedback) else {
                return L10n.string("session.notice.active", defaultValue: "Session active")
            }

            return L10n.string(
                "session.notice.active.detail_format",
                defaultValue: "Session active - %@",
                arguments: [detail]
            )
        case .restored(let feedback):
            guard let detail = localizedDetail(for: feedback) else {
                return L10n.string("session.notice.restored", defaultValue: "Session restored")
            }

            return L10n.string(
                "session.notice.restored.detail_format",
                defaultValue: "Session restored - %@",
                arguments: [detail]
            )
        }
    }

    var lastActionDetail: String? {
        switch lastActionState {
        case .active(let feedback):
            return localizedDetail(for: feedback)
        case .restored(let feedback):
            return localizedDetail(for: feedback)
        default:
            return nil
        }
    }

    var isCheckingHiddenApps: Bool {
        switch lastActionState {
        case .restored(let feedback):
            return feedback.isVisibilityPending
        default:
            return false
        }
    }

    var restoreHasVisibilityLimit: Bool {
        switch lastActionState {
        case .restored(let feedback):
            return feedback.stillHiddenApplicationsCount > 0
        default:
            return false
        }
    }

    func startIfPossible(with preset: Preset?) {
        guard let preset else {
            sessionPhase = activeSnapshot == nil ? .inactive : sessionPhase
            lastActionState = .selectPresetBeforeStarting
            return
        }

        start(with: preset)
    }

    func start(with preset: Preset) {
        visibilityConfirmationTask?.cancel()
        restoreVisibilityTask?.cancel()

        guard activeSnapshot == nil else {
            lastActionState = .restoreBeforeStartingAnother
            return
        }

        guard preset.hasStartableActions else {
            pendingHiddenApplicationCandidates = []
            sessionPhase = .inactive
            lastActionState = .addRunnableActionBeforeStarting
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
                lastActionState = .nothingOpened
            } else {
                lastActionState = .addRunnableActionBeforeStarting
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
                lastActionState = .noActiveSessionToRestore
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
        lastActionState = .active(
            ActiveSessionFeedback(
                confirmedHiddenApplicationCount: confirmedHiddenApplicationCount,
                unresolvedHiddenApplicationCount: unresolvedHiddenApplicationCount,
                launchFailureCount: launchFailureCount,
                visibilityFailureCount: visibilityFailureCount,
                overlayWasRequested: overlayWasRequested,
                overlayWasShown: overlayWasShown,
                isVisibilityPending: isVisibilityPending
            )
        )
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
        lastActionState = .restored(
            RestoreSessionFeedback(
                hidOverlay: restoreResult.hidOverlay,
                revealedApplicationsCount: revealedApplicationsCount,
                stillHiddenApplicationsCount: stillHiddenApplicationsCount,
                closedApplicationsCount: restoreResult.closedApplicationsCount,
                stillRunningApplicationsCount: restoreResult.stillRunningApplicationsCount,
                isVisibilityPending: isVisibilityPending
            )
        )
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

    private func localizedDetail(for feedback: ActiveSessionFeedback) -> String? {
        var statusNotes: [String] = []

        if feedback.confirmedHiddenApplicationCount > 0 {
            statusNotes.append(
                localizedCount(
                    feedback.confirmedHiddenApplicationCount,
                    oneKey: "session.notice.active.hidden.one",
                    otherKey: "session.notice.active.hidden.other",
                    defaultOne: "%d app hidden",
                    defaultOther: "%d apps hidden"
                )
            )
        }

        if feedback.isVisibilityPending && feedback.confirmedHiddenApplicationCount + feedback.unresolvedHiddenApplicationCount > 0 {
            statusNotes.append(
                L10n.string(
                    "session.notice.active.checking_visibility",
                    defaultValue: "checking app visibility"
                )
            )
        } else if feedback.unresolvedHiddenApplicationCount > 0 {
            statusNotes.append(
                localizedCount(
                    feedback.unresolvedHiddenApplicationCount,
                    oneKey: "session.notice.active.stayed_visible.one",
                    otherKey: "session.notice.active.stayed_visible.other",
                    defaultOne: "%d app stayed visible",
                    defaultOther: "%d apps stayed visible"
                )
            )
        }

        if feedback.launchFailureCount > 0 {
            statusNotes.append(
                L10n.string(
                    "session.notice.active.open_failed",
                    defaultValue: "%d items could not be opened",
                    arguments: [feedback.launchFailureCount]
                )
            )
        }

        if feedback.visibilityFailureCount > 0 {
            statusNotes.append(
                localizedCount(
                    feedback.visibilityFailureCount,
                    oneKey: "session.notice.active.skipped.one",
                    otherKey: "session.notice.active.skipped.other",
                    defaultOne: "%d app skipped",
                    defaultOther: "%d apps skipped"
                )
            )
        }

        if feedback.overlayWasRequested && !feedback.overlayWasShown {
            statusNotes.append(
                L10n.string(
                    "session.notice.active.clean_screen_unavailable",
                    defaultValue: "clean screen unavailable"
                )
            )
        }

        return statusNotes.isEmpty ? nil : statusNotes.joined(separator: ", ")
    }

    private func localizedDetail(for feedback: RestoreSessionFeedback) -> String? {
        var restoredItems: [String] = []

        if feedback.hidOverlay {
            restoredItems.append(
                L10n.string(
                    "session.notice.restore.overlay_hidden",
                    defaultValue: "clean screen hidden"
                )
            )
        }

        if feedback.isVisibilityPending {
            restoredItems.append(
                L10n.string(
                    "session.notice.restore.checking_hidden_apps",
                    defaultValue: "checking hidden apps"
                )
            )
        } else {
            if feedback.revealedApplicationsCount > 0 {
                restoredItems.append(
                    localizedCount(
                        feedback.revealedApplicationsCount,
                        oneKey: "session.notice.restore.shown_again.one",
                        otherKey: "session.notice.restore.shown_again.other",
                        defaultOne: "%d hidden app shown again",
                        defaultOther: "%d hidden apps shown again"
                    )
                )
            }

            if feedback.stillHiddenApplicationsCount > 0 {
                restoredItems.append(
                    localizedCount(
                        feedback.stillHiddenApplicationsCount,
                        oneKey: "session.notice.restore.still_hidden.one",
                        otherKey: "session.notice.restore.still_hidden.other",
                        defaultOne: "%d hidden app may still be hidden",
                        defaultOther: "%d hidden apps may still be hidden"
                    )
                )
            }
        }

        if feedback.closedApplicationsCount > 0 {
            restoredItems.append(
                localizedCount(
                    feedback.closedApplicationsCount,
                    oneKey: "session.notice.restore.closed.one",
                    otherKey: "session.notice.restore.closed.other",
                    defaultOne: "%d launched app closed",
                    defaultOther: "%d launched apps closed"
                )
            )
        }

        if feedback.stillRunningApplicationsCount > 0 {
            restoredItems.append(
                localizedCount(
                    feedback.stillRunningApplicationsCount,
                    oneKey: "session.notice.restore.still_open.one",
                    otherKey: "session.notice.restore.still_open.other",
                    defaultOne: "%d launched app may still be open",
                    defaultOther: "%d launched apps may still be open"
                )
            )
        }

        return restoredItems.isEmpty ? nil : restoredItems.joined(separator: ", ")
    }

    private func localizedCount(
        _ count: Int,
        oneKey: String,
        otherKey: String,
        defaultOne: String,
        defaultOther: String
    ) -> String {
        let key = count == 1 ? oneKey : otherKey
        let defaultValue = count == 1 ? defaultOne : defaultOther
        return L10n.string(key, defaultValue: defaultValue, arguments: [count])
    }
}
