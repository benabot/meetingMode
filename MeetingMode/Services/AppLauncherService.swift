import AppKit
import Foundation

struct LaunchExecutionResult {
    var launchedApplications: [String] = []
    var launchedApplicationBundleIdentifiers: [String] = []
    var failureCount = 0
}

struct ContentExecutionResult {
    var openedURLs: [String] = []
    var openedFiles: [String] = []
    var failureCount = 0
}

struct ContentRestoreResult {
    var cleanedURLsCount = 0
    var skippedFilesCount = 0
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

        return result
    }

    func openContent(for preset: Preset) -> ContentExecutionResult {
        var result = ContentExecutionResult()

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

    func closeContent(from snapshot: SessionSnapshot) -> ContentRestoreResult {
        var result = ContentRestoreResult()
        result.skippedFilesCount = snapshot.openedFiles.count

        let browserTargets = browserCleanupTargets()
        guard !browserTargets.isEmpty else {
            return result
        }

        for openedURL in snapshot.openedURLs {
            if closeBrowserContent(from: openedURL, using: browserTargets) {
                result.cleanedURLsCount += 1
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

        return openWithConfiguration(url)  ? trimmedURL : nil
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
        return openWithConfiguration(fileURL) ? expandedPath : nil
    }

    private func openWithConfiguration(_ url: URL, timeout: TimeInterval = 3.0) -> Bool {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        var didFinish = false
        var openSucceeded = false

        NSWorkspace.shared.open(url, configuration: configuration) { _, error in
            openSucceeded = error == nil
            didFinish = true
        }

        let deadline = Date().addingTimeInterval(timeout)
        while !didFinish && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        return openSucceeded
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

    private func browserCleanupTargets() -> [BrowserCleanupTarget] {
        let frontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        return Self.browserCleanupCatalog
            .filter { isApplicationRunning(bundleIdentifier: $0.bundleIdentifier) }
            .sorted {
                if $0.bundleIdentifier == frontmostBundleIdentifier {
                    return true
                }

                if $1.bundleIdentifier == frontmostBundleIdentifier {
                    return false
                }

                return $0.priority < $1.priority
            }
    }

    private func closeBrowserContent(from urlString: String, using browserTargets: [BrowserCleanupTarget]) -> Bool {
        let candidateURLs = browserCleanupCandidates(for: urlString)
        guard !candidateURLs.isEmpty else {
            return false
        }

        for browserTarget in browserTargets {
            let candidateList = candidateURLs
                .map(Self.appleScriptStringLiteral)
                .joined(separator: ", ")

            let scriptSource = """
            tell application "\(browserTarget.appleScriptName)"
                if not running then return "0"
                set candidateURLs to {\(candidateList)}
                repeat with browserWindow in windows
                    repeat with browserTab in tabs of browserWindow
                        if (URL of browserTab as text) is in candidateURLs then
                            close browserTab
                            return "1"
                        end if
                    end repeat
                end repeat
                return "0"
            end tell
            """

            if executeAppleScript(scriptSource) {
                return true
            }
        }

        return false
    }

    private func browserCleanupCandidates(for urlString: String) -> [String] {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty,
              let url = URL(string: trimmedURL),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              Self.browserCleanupSchemes.contains(scheme),
              let host = components.host?.lowercased() else {
            return []
        }

        let path = components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath
        let query = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        let fragment = components.percentEncodedFragment.map { "#\($0)" } ?? ""
        let port = components.port.map { ":\($0)" } ?? ""

        var candidates = Set<String>()
        candidates.insert(trimmedURL)
        candidates.insert(url.absoluteString)
        candidates.insert("\(scheme)://\(host)\(port)\(path)\(query)\(fragment)")

        if path == "/" {
            candidates.insert("\(scheme)://\(host)\(port)")
            candidates.insert("\(scheme)://\(host)\(port)/")
        }

        return Array(candidates)
    }

    private func executeAppleScript(_ source: String) -> Bool {
        guard let script = NSAppleScript(source: source) else {
            return false
        }

        var error: NSDictionary?
        let descriptor = script.executeAndReturnError(&error)
        guard let result = descriptor.stringValue else {
            return false
        }

        return result == "1"
    }

    private static func appleScriptStringLiteral(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}

private struct OpenedApplication {
    let displayName: String
    let bundleIdentifier: String?
    let shouldTerminateOnRestore: Bool
}

private struct BrowserCleanupTarget {
    let bundleIdentifier: String
    let appleScriptName: String
    let priority: Int
}

private extension AppLauncherService {
    static let browserCleanupCatalog: [BrowserCleanupTarget] = [
        BrowserCleanupTarget(
            bundleIdentifier: "com.apple.Safari",
            appleScriptName: "Safari",
            priority: 0
        ),
        BrowserCleanupTarget(
            bundleIdentifier: "com.google.Chrome",
            appleScriptName: "Google Chrome",
            priority: 1
        ),
    ]

    static let browserCleanupSchemes: Set<String> = [
        "http",
        "https",
    ]
}
