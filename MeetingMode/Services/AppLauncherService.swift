import AppKit
import Foundation

struct LaunchExecutionResult {
    var launchedApplications: [String] = []
    var launchedApplicationBundleIdentifiers: [String] = []
    var openedURLs: [String] = []
    var openedFiles: [String] = []
    var failureCount = 0
}

struct ApplicationRestoreResult {
    var closedApplicationsCount = 0
    var stillRunningApplicationsCount = 0
}

@MainActor
final class AppLauncherService: AppLaunching {
    func openItems(for preset: Preset) -> LaunchExecutionResult {
        var result = LaunchExecutionResult()

        for application in preset.appsToLaunch {
            if let launchedApplication = openApplication(reference: application) {
                result.launchedApplications.append(launchedApplication.displayName)
                if launchedApplication.shouldTerminateOnRestore,
                   let bundleIdentifier = launchedApplication.bundleIdentifier {
                    result.launchedApplicationBundleIdentifiers.append(bundleIdentifier)
                }
            } else if application.hasLaunchTarget {
                result.failureCount += 1
            }
        }

        for urlString in preset.urlsToOpen {
            if let openedURL = openURL(from: urlString) {
                result.openedURLs.append(openedURL)
            } else if !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.failureCount += 1
            }
        }

        for filePath in preset.filesToOpen {
            if let openedFile = openFile(at: filePath) {
                result.openedFiles.append(openedFile)
            } else if !filePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.failureCount += 1
            }
        }

        return result
    }

    func restoreApplications(from snapshot: SessionSnapshot) -> ApplicationRestoreResult {
        var result = ApplicationRestoreResult()
        let bundleIdentifiers = Set(snapshot.launchedApplicationBundleIdentifiers)

        for bundleIdentifier in bundleIdentifiers {
            let runningApplications = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == bundleIdentifier && !$0.isTerminated
            }

            for application in runningApplications {
                if closeApplication(application) {
                    result.closedApplicationsCount += 1
                } else {
                    result.stillRunningApplicationsCount += 1
                }
            }
        }

        return result
    }

    private func openApplication(reference: PresetApp) -> OpenedApplication? {
        guard let applicationURL = resolvedApplicationURL(for: reference) else {
            return nil
        }

        let bundleIdentifier = reference.normalizedBundleIdentifier
            ?? Bundle(url: applicationURL)?.bundleIdentifier
        let wasRunningBeforeLaunch = bundleIdentifier.map(isApplicationRunning(bundleIdentifier:)) ?? false

        // Launch the app bundle as an application. Using open(_:) on a .app URL can
        // fall back to Finder-like file opening instead of launching the app.
        let runningApplication: NSRunningApplication
        do {
            runningApplication = try NSWorkspace.shared.launchApplication(
                at: applicationURL,
                options: [],
                configuration: [:]
            )
        } catch {
            return nil
        }

        return OpenedApplication(
            displayName: runningApplication.localizedName ?? applicationURL.deletingPathExtension().lastPathComponent,
            bundleIdentifier: runningApplication.bundleIdentifier ?? bundleIdentifier,
            shouldTerminateOnRestore: !wasRunningBeforeLaunch
        )
    }

    private func openURL(from urlString: String) -> String? {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty,
              let url = URL(string: trimmedURL),
              url.scheme != nil else {
            return nil
        }

        return NSWorkspace.shared.open(url) ? trimmedURL : nil
    }

    private func openFile(at filePath: String) -> String? {
        let trimmedPath = filePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            return nil
        }

        let expandedPath = NSString(string: trimmedPath).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return nil
        }

        let fileURL = URL(fileURLWithPath: expandedPath)
        return NSWorkspace.shared.open(fileURL) ? expandedPath : nil
    }

    private func resolvedApplicationURL(for application: PresetApp) -> URL? {
        let fileManager = FileManager.default

        if let bundleIdentifier = application.normalizedBundleIdentifier,
           let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
           fileManager.fileExists(atPath: applicationURL.path) {
            return applicationURL
        }

        if let bundlePath = application.normalizedBundlePath {
            let expandedPath = NSString(string: bundlePath).expandingTildeInPath
            if fileManager.fileExists(atPath: expandedPath) {
                return URL(fileURLWithPath: expandedPath)
            }
        }

        let applicationName = application.normalizedDisplayName
        guard !applicationName.isEmpty else {
            return nil
        }

        return resolvedApplicationURL(named: applicationName)
    }

    private func resolvedApplicationURL(named applicationName: String) -> URL? {
        let fileManager = FileManager.default
        let applicationDirectories = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
        ]
        let candidateNames = applicationName.hasSuffix(".app")
            ? [applicationName]
            : [applicationName, "\(applicationName).app"]

        for directory in applicationDirectories {
            for candidateName in candidateNames {
                let applicationURL = directory.appendingPathComponent(candidateName)
                if fileManager.fileExists(atPath: applicationURL.path) {
                    return applicationURL
                }
            }
        }

        return nil
    }

    private func isApplicationRunning(bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleIdentifier && !$0.isTerminated
        }
    }

    private func waitForTermination(
        of application: NSRunningApplication,
        timeout: TimeInterval = 1.0
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while !application.isTerminated && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        return application.isTerminated
    }

    private func closeApplication(_ application: NSRunningApplication) -> Bool {
        if application.isTerminated {
            return true
        }

        if application.terminate(),
           waitForTermination(of: application, timeout: 1.5) {
            return true
        }

        if application.isTerminated {
            return true
        }

        if application.forceTerminate() {
            return waitForTermination(of: application, timeout: 1.0)
        }

        return application.isTerminated
    }
}

private struct OpenedApplication {
    let displayName: String
    let bundleIdentifier: String?
    let shouldTerminateOnRestore: Bool
}
