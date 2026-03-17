import Foundation

@testable import MeetingMode

@MainActor
struct MockAppLauncher: AppLaunching {
    var openItemsResult = LaunchExecutionResult()

    func openItems(for preset: Preset) -> LaunchExecutionResult {
        openItemsResult
    }
}

@MainActor
struct MockAppVisibility: AppVisibilityManaging {
    var hideResult = VisibilityExecutionResult()
    var confirmHiddenResult = VisibilityConfirmationResult()
    var confirmVisibleResult = VisibilityRevealConfirmationResult()
    var openFallbacksResult: [HiddenApplicationSnapshot] = []

    func hideNonPresetVisibleApps(keepingVisibleFor preset: Preset) -> VisibilityExecutionResult {
        hideResult
    }

    func confirmHiddenApplications(
        from requestedApplications: [HiddenApplicationSnapshot],
        timeout: TimeInterval
    ) -> VisibilityConfirmationResult {
        confirmHiddenResult
    }

    func confirmVisibleApplications(
        from requestedApplications: [HiddenApplicationSnapshot],
        timeout: TimeInterval
    ) -> VisibilityRevealConfirmationResult {
        confirmVisibleResult
    }

    func requestOpenFallbacks(
        for trackedApplications: [HiddenApplicationSnapshot]
    ) -> [HiddenApplicationSnapshot] {
        openFallbacksResult
    }
}

@MainActor
struct MockOverlay: OverlayProviding {
    var showOverlayResult = true

    func showOverlay() -> Bool {
        showOverlayResult
    }
}

@MainActor
struct MockRestore: SessionRestoring {
    var restoreResult = RestoreExecutionResult()

    func restore(from snapshot: SessionSnapshot) -> RestoreExecutionResult {
        restoreResult
    }
}
