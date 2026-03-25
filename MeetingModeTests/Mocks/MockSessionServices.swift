import Foundation

@testable import MeetingMode

struct MockAppLauncher: AppLaunching {
    var openItemsResult = LaunchExecutionResult()
    var openContentResult = ContentExecutionResult()
    var closeContentResult = ContentRestoreResult()
    let openContentLaunchContext = MockAppLauncherLaunchContext()

    func openItems(for preset: Preset) -> LaunchExecutionResult {
        openItemsResult
    }

    func openContent(
        for preset: Preset,
        launchedApplicationBundleIdentifiers: Set<String>
    ) -> ContentExecutionResult {
        openContentLaunchContext.launchedApplicationBundleIdentifiers.append(launchedApplicationBundleIdentifiers)
        return openContentResult
    }

    func closeContent(
        from snapshot: SessionSnapshot,
        closedApplicationBundleIdentifiers: Set<String>
    ) -> ContentRestoreResult {
        closeContentResult
    }
}

final class MockAppLauncherLaunchContext {
    var launchedApplicationBundleIdentifiers: [Set<String>] = []
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
    let capture = MockOverlayCapture()

    func showOverlay(using background: PresentationBackground) -> Bool {
        capture.backgrounds.append(background)
        return showOverlayResult
    }
}

final class MockOverlayCapture {
    var backgrounds: [PresentationBackground] = []
}

@MainActor
struct MockRestore: SessionRestoring {
    var restoreResult = RestoreExecutionResult()

    func restore(from snapshot: SessionSnapshot) -> RestoreExecutionResult {
        restoreResult
    }
}
