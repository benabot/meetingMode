import Foundation

@MainActor
protocol AppLaunching {
    func openItems(for preset: Preset) -> LaunchExecutionResult
    func openContent(for preset: Preset) -> ContentExecutionResult
}

@MainActor
protocol AppVisibilityManaging {
    func hideNonPresetVisibleApps(keepingVisibleFor preset: Preset) -> VisibilityExecutionResult
    func confirmHiddenApplications(
        from requestedApplications: [HiddenApplicationSnapshot],
        timeout: TimeInterval
    ) -> VisibilityConfirmationResult
    func confirmVisibleApplications(
        from requestedApplications: [HiddenApplicationSnapshot],
        timeout: TimeInterval
    ) -> VisibilityRevealConfirmationResult
    func requestOpenFallbacks(
        for trackedApplications: [HiddenApplicationSnapshot]
    ) -> [HiddenApplicationSnapshot]
}

@MainActor
protocol OverlayProviding {
    func showOverlay() -> Bool
}

@MainActor
protocol SessionRestoring {
    func restore(from snapshot: SessionSnapshot) -> RestoreExecutionResult
}
