import AppKit
import Foundation
import OSLog

struct VisibilityExecutionResult {
    var requestedApplications: [HiddenApplicationSnapshot] = []
    var hiddenApplications: [HiddenApplicationSnapshot] = []
    var failureCount = 0

    var requestedApplicationCount: Int {
        requestedApplications.count
    }

    var hiddenApplicationCount: Int {
        hiddenApplications.count
    }
}

struct VisibilityConfirmationResult {
    var hiddenApplications: [HiddenApplicationSnapshot] = []
    var stillVisibleApplications: [HiddenApplicationSnapshot] = []

    var hiddenApplicationCount: Int {
        hiddenApplications.count
    }
}

struct VisibilityRevealConfirmationResult {
    var revealedApplications: [HiddenApplicationSnapshot] = []
    var stillHiddenApplications: [HiddenApplicationSnapshot] = []
}

@MainActor
final class AppVisibilityService: AppVisibilityManaging {
    private let logger = Logger(subsystem: "fr.beabot.meetingmode", category: "AppVisibility")
    private let meetingModeBundleIdentifier: String?

    init(meetingModeBundleIdentifier: String? = Bundle.main.bundleIdentifier) {
        self.meetingModeBundleIdentifier = meetingModeBundleIdentifier
    }

    func hideNonPresetVisibleApps(keepingVisibleFor preset: Preset) -> VisibilityExecutionResult {
        let protectedApplications = ProtectedApplications(preset: preset)
        var result = VisibilityExecutionResult()

        for application in NSWorkspace.shared.runningApplications where shouldManage(application) {
            guard !protectedApplications.matches(application) else {
                continue
            }

            guard let bundleIdentifier = application.bundleIdentifier else {
                logger.notice("Hide skipped for app without bundle id pid=\(application.processIdentifier, privacy: .public)")
                result.failureCount += 1
                continue
            }

            let hiddenApplication = HiddenApplicationSnapshot(
                bundleIdentifier: bundleIdentifier,
                processIdentifier: application.processIdentifier,
                localizedName: application.localizedName ?? bundleIdentifier,
                bundlePath: application.bundleURL?.path
            )

            logger.notice("Hide attempt \(self.logLabel(for: application), privacy: .public)")

            let hideRequested = application.hide()
            logger.notice("Hide requested=\(hideRequested, privacy: .public) \(self.logLabel(for: application), privacy: .public)")

            if !result.requestedApplications.contains(hiddenApplication) {
                result.requestedApplications.append(hiddenApplication)
            }
        }

        return result
    }

    func confirmHiddenApplications(
        from requestedApplications: [HiddenApplicationSnapshot],
        timeout: TimeInterval = 2.0
    ) -> VisibilityConfirmationResult {
        let uniqueApplications = Array(Set(requestedApplications))
        guard !uniqueApplications.isEmpty else {
            return VisibilityConfirmationResult()
        }

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let hiddenApplications = uniqueApplications.filter(isTrackedApplicationHidden(_:))
            if hiddenApplications.count == uniqueApplications.count {
                break
            }

            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        let hiddenApplications = uniqueApplications.filter(isTrackedApplicationHidden(_:))
        let hiddenSet = Set(hiddenApplications)
        let stillVisibleApplications = uniqueApplications.filter { !hiddenSet.contains($0) }

        for hiddenApplication in hiddenApplications {
            logger.notice(
                "Hide confirmed bundle=\(hiddenApplication.bundleIdentifier, privacy: .public) pid=\(hiddenApplication.processIdentifier, privacy: .public) name=\(hiddenApplication.localizedName, privacy: .public)"
            )
        }

        for visibleApplication in stillVisibleApplications {
            logger.notice(
                "Hide not confirmed bundle=\(visibleApplication.bundleIdentifier, privacy: .public) pid=\(visibleApplication.processIdentifier, privacy: .public) name=\(visibleApplication.localizedName, privacy: .public)"
            )
        }

        return VisibilityConfirmationResult(
            hiddenApplications: hiddenApplications,
            stillVisibleApplications: stillVisibleApplications
        )
    }

    func beginVisibilityRestore(from snapshot: SessionSnapshot) -> [HiddenApplicationSnapshot] {
        var restoreCandidates: [HiddenApplicationSnapshot] = []

        for hiddenApplication in snapshot.hiddenApplications {
            logger.notice(
                "Restore target bundle=\(hiddenApplication.bundleIdentifier, privacy: .public) pid=\(hiddenApplication.processIdentifier, privacy: .public) name=\(hiddenApplication.localizedName, privacy: .public)"
            )
            let runningApplications = runningApplications(matching: hiddenApplication)
            logger.notice("Restore found \(runningApplications.count, privacy: .public) running matches for \(hiddenApplication.localizedName, privacy: .public)")

            guard let application = runningApplications.first(where: {
                shouldRestore($0, trackedApplication: hiddenApplication)
            }) else {
                continue
            }

            requestRestoreVisibility(for: application)

            if !restoreCandidates.contains(hiddenApplication) {
                restoreCandidates.append(hiddenApplication)
            }
        }

        return restoreCandidates
    }

    func requestOpenFallbacks(
        for trackedApplications: [HiddenApplicationSnapshot]
    ) -> [HiddenApplicationSnapshot] {
        let uniqueApplications = Array(Set(trackedApplications))
        var fallbackCandidates: [HiddenApplicationSnapshot] = []

        for hiddenApplication in uniqueApplications {
            let runningApplications = runningApplications(matching: hiddenApplication)

            guard let application = runningApplications.first(where: {
                !$0.isTerminated
                    && $0.activationPolicy == .regular
                    && $0.bundleIdentifier == hiddenApplication.bundleIdentifier
            }) else {
                logger.notice(
                    "Open fallback skipped bundle=\(hiddenApplication.bundleIdentifier, privacy: .public) pid=\(hiddenApplication.processIdentifier, privacy: .public) name=\(hiddenApplication.localizedName, privacy: .public)"
                )
                continue
            }

            if requestOpenFallback(application, trackedApplication: hiddenApplication) {
                fallbackCandidates.append(hiddenApplication)
            } else {
                logger.notice("Open fallback unavailable \(self.logLabel(for: application), privacy: .public)")
            }
        }

        return fallbackCandidates
    }

    private func runningApplications(
        matching hiddenApplication: HiddenApplicationSnapshot
    ) -> [NSRunningApplication] {
        let regularRunningApplications = NSWorkspace.shared.runningApplications.filter {
            !$0.isTerminated && $0.activationPolicy == .regular
        }

        if hiddenApplication.processIdentifier > 0 {
            let processMatches = regularRunningApplications.filter {
                $0.processIdentifier == hiddenApplication.processIdentifier
            }

            if !processMatches.isEmpty {
                return processMatches
            }
        }

        return regularRunningApplications.filter {
            $0.bundleIdentifier == hiddenApplication.bundleIdentifier
        }
    }

    private func shouldRestore(
        _ application: NSRunningApplication,
        trackedApplication: HiddenApplicationSnapshot
    ) -> Bool {
        guard !application.isTerminated else {
            return false
        }

        guard application.activationPolicy == .regular else {
            return false
        }

        guard application.bundleIdentifier == trackedApplication.bundleIdentifier else {
            return false
        }

        return application.isHidden
    }

    private func shouldManage(_ application: NSRunningApplication) -> Bool {
        guard !application.isTerminated else {
            return false
        }

        guard application.activationPolicy == .regular else {
            return false
        }

        guard !application.isHidden else {
            return false
        }

        if let meetingModeBundleIdentifier,
           application.bundleIdentifier == meetingModeBundleIdentifier {
            return false
        }

        return true
    }

    private func requestRestoreVisibility(for application: NSRunningApplication) {
        logger.notice("Unhide attempt \(self.logLabel(for: application), privacy: .public)")

        let unhideRequested = application.unhide()
        logger.notice("Unhide requested=\(unhideRequested, privacy: .public) \(self.logLabel(for: application), privacy: .public)")

        let activateRequested = application.activate(options: [.activateAllWindows])
        logger.notice("Activate requested=\(activateRequested, privacy: .public) \(self.logLabel(for: application), privacy: .public)")
    }

    private func requestOpenFallback(
        _ application: NSRunningApplication,
        trackedApplication: HiddenApplicationSnapshot
    ) -> Bool {
        guard !application.isTerminated,
              let applicationURL = restoredApplicationURL(
                for: application,
                trackedApplication: trackedApplication
              ) else {
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.addsToRecentItems = false
        configuration.createsNewApplicationInstance = false

        logger.notice("Open fallback attempt bundleURL=\(applicationURL.path, privacy: .public) \(self.logLabel(for: application), privacy: .public)")

        var didFinish = false
        var completionError: Error?

        NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) { _, error in
            completionError = error
            didFinish = true
        }

        let deadline = Date().addingTimeInterval(2.5)
        while !didFinish && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        guard completionError == nil else {
            logger.notice("Open fallback request failed hidden=\(application.isHidden, privacy: .public) error=\(String(describing: completionError), privacy: .public) \(self.logLabel(for: application), privacy: .public)")
            return false
        }

        logger.notice("Open fallback requested hidden=\(application.isHidden, privacy: .public) \(self.logLabel(for: application), privacy: .public)")
        return true
    }

    private func restoredApplicationURL(
        for application: NSRunningApplication,
        trackedApplication: HiddenApplicationSnapshot
    ) -> URL? {
        if let bundleURL = application.bundleURL {
            return bundleURL
        }

        guard let bundlePath = trackedApplication.bundlePath,
              !bundlePath.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: bundlePath)
    }

    private func waitForTrackedVisibility(
        of trackedApplication: HiddenApplicationSnapshot,
        expectingHidden: Bool,
        timeout: TimeInterval = 2.5
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if runningApplications(matching: trackedApplication).contains(where: { $0.isHidden == expectingHidden && !$0.isTerminated }) {
                return true
            }

            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        return runningApplications(matching: trackedApplication).contains(where: { $0.isHidden == expectingHidden && !$0.isTerminated })
    }

    private func isTrackedApplicationHidden(_ trackedApplication: HiddenApplicationSnapshot) -> Bool {
        runningApplications(matching: trackedApplication).contains {
            $0.isHidden && !$0.isTerminated
        }
    }

    func confirmVisibleApplications(
        from requestedApplications: [HiddenApplicationSnapshot],
        timeout: TimeInterval
    ) -> VisibilityRevealConfirmationResult {
        let uniqueApplications = Array(Set(requestedApplications))
        guard !uniqueApplications.isEmpty else {
            return VisibilityRevealConfirmationResult()
        }

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let stillHiddenApplications = uniqueApplications.filter(isTrackedApplicationHidden(_:))
            if stillHiddenApplications.isEmpty {
                break
            }

            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        let stillHiddenApplications = uniqueApplications.filter(isTrackedApplicationHidden(_:))
        let stillHiddenSet = Set(stillHiddenApplications)
        let revealedApplications = uniqueApplications.filter { !stillHiddenSet.contains($0) }

        for revealedApplication in revealedApplications {
            logger.notice(
                "Restore confirmed bundle=\(revealedApplication.bundleIdentifier, privacy: .public) pid=\(revealedApplication.processIdentifier, privacy: .public) name=\(revealedApplication.localizedName, privacy: .public)"
            )
        }

        for hiddenApplication in stillHiddenApplications {
            logger.notice(
                "Restore still hidden bundle=\(hiddenApplication.bundleIdentifier, privacy: .public) pid=\(hiddenApplication.processIdentifier, privacy: .public) name=\(hiddenApplication.localizedName, privacy: .public)"
            )
        }

        return VisibilityRevealConfirmationResult(
            revealedApplications: revealedApplications,
            stillHiddenApplications: stillHiddenApplications
        )
    }

    private func logLabel(for application: NSRunningApplication) -> String {
        let name = application.localizedName ?? "Unknown"
        let bundleIdentifier = application.bundleIdentifier ?? "no-bundle-id"
        return "name=\(name) bundle=\(bundleIdentifier) pid=\(application.processIdentifier) hidden=\(application.isHidden)"
    }
}

private struct ProtectedApplications {
    let bundleIdentifiers: Set<String>
    let bundlePaths: Set<String>
    let displayNames: Set<String>

    init(preset: Preset) {
        bundleIdentifiers = Set(
            preset.appsToLaunch.compactMap { $0.normalizedBundleIdentifier }
        )
        bundlePaths = Set(
            preset.appsToLaunch.compactMap { app in
                guard let path = app.normalizedBundlePath else {
                    return nil
                }

                return URL(fileURLWithPath: path).standardizedFileURL.path
            }
        )
        displayNames = Set(
            preset.appsToLaunch
                .map { $0.normalizedDisplayName.lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    func matches(_ application: NSRunningApplication) -> Bool {
        if let bundleIdentifier = application.bundleIdentifier,
           bundleIdentifiers.contains(bundleIdentifier) {
            return true
        }

        if let bundleURL = application.bundleURL?.standardizedFileURL.path,
           bundlePaths.contains(bundleURL) {
            return true
        }

        if let localizedName = application.localizedName?.lowercased(),
           displayNames.contains(localizedName) {
            return true
        }

        return false
    }
}
