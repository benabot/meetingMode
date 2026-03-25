import XCTest

@testable import MeetingMode

final class SessionRunnerTests: XCTestCase {
    private var tempDirectory: URL!
    private var snapshotStorageURL: URL!

    override func setUp() {
        super.setUp()
        let uniqueID = UUID().uuidString
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SessionRunnerTests-\(uniqueID)", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        snapshotStorageURL = tempDirectory.appendingPathComponent("active_session.json")
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        super.tearDown()
    }

    @MainActor
    private func makeRunner(
        launcher: MockAppLauncher? = nil,
        visibility: MockAppVisibility? = nil,
        overlay: MockOverlay? = nil,
        restore: MockRestore? = nil
    ) -> SessionRunner {
        SessionRunner(
            appLauncherService: launcher ?? MockAppLauncher(),
            appVisibilityService: visibility ?? MockAppVisibility(),
            overlayService: overlay ?? MockOverlay(),
            restoreService: restore ?? MockRestore(),
            snapshotStorageURL: snapshotStorageURL
        )
    }

    // MARK: - Start guards

    func test_startWithNilPreset_selectPresetState() async {
        await MainActor.run {
            let runner = makeRunner()

            runner.startIfPossible(with: nil)

            XCTAssertEqual(runner.lastActionState, .selectPresetBeforeStarting)
            XCTAssertEqual(runner.sessionPhase, .inactive)
        }
    }

    func test_startWithEmptyPreset_addRunnableActionState() async {
        await MainActor.run {
            let runner = makeRunner()
            let preset = Preset(name: "Empty")

            runner.start(with: preset)

            XCTAssertEqual(runner.lastActionState, .addRunnableActionBeforeStarting)
            XCTAssertEqual(runner.sessionPhase, .inactive)
        }
    }

    func test_startWhileActive_restoreBeforeStartingState() async {
        await MainActor.run {
            var launcher = MockAppLauncher()
            launcher.openItemsResult = LaunchExecutionResult(
                launchedApplications: ["Calculator"],
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
            let runner = makeRunner(launcher: launcher)
            let preset = Preset(
                name: "Test",
                appsToLaunch: [
                    PresetApp(
                        displayName: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        bundlePath: "/System/Applications/Calculator.app"
                    ),
                ]
            )

            runner.start(with: preset)
            XCTAssertEqual(runner.sessionPhase, .active)

            runner.start(with: preset)
            XCTAssertEqual(runner.lastActionState, .restoreBeforeStartingAnother)
        }
    }

    // MARK: - Successful start

    func test_startSuccess_activePhaseAndSnapshot() async {
        await MainActor.run {
            var launcher = MockAppLauncher()
            launcher.openItemsResult = LaunchExecutionResult(
                launchedApplications: ["Calculator"],
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
            var overlay = MockOverlay()
            overlay.showOverlayResult = true
            let runner = makeRunner(launcher: launcher, overlay: overlay)
            let preset = Preset(
                name: "Demo",
                appsToLaunch: [
                    PresetApp(
                        displayName: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        bundlePath: "/System/Applications/Calculator.app"
                    ),
                ],
                showsOverlay: true
            )

            runner.start(with: preset)

            XCTAssertEqual(runner.sessionPhase, .active)
            XCTAssertNotNil(runner.activeSnapshot)
            XCTAssertEqual(runner.activeSnapshot?.launchedApplications, ["Calculator"])
        }
    }

    func test_startPassesLaunchedAppBundleIdentifiersToContentOpening() async {
        await MainActor.run {
            var launcher = MockAppLauncher()
            launcher.openItemsResult = LaunchExecutionResult(
                launchedApplications: ["Calculator"],
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
            let runner = makeRunner(launcher: launcher)
            let preset = Preset(
                name: "Demo",
                appsToLaunch: [
                    PresetApp(
                        displayName: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        bundlePath: "/System/Applications/Calculator.app"
                    ),
                ]
            )

            runner.start(with: preset)

            XCTAssertEqual(
                launcher.openContentLaunchContext.launchedApplicationBundleIdentifiers,
                [Set(["com.apple.calculator"])]
            )
        }
    }

    // MARK: - Restore guards

    func test_restoreWithNoSession_noActiveSessionState() async {
        await MainActor.run {
            let runner = makeRunner()

            runner.restoreIfPossible()

            XCTAssertEqual(runner.lastActionState, .noActiveSessionToRestore)
        }
    }

    // MARK: - Successful restore

    func test_restoreSuccess_restoredPhaseAndNilSnapshot() async {
        await MainActor.run {
            var launcher = MockAppLauncher()
            launcher.openItemsResult = LaunchExecutionResult(
                launchedApplications: ["Calculator"],
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
            let runner = makeRunner(launcher: launcher)
            let preset = Preset(
                name: "Test",
                appsToLaunch: [
                    PresetApp(
                        displayName: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        bundlePath: "/System/Applications/Calculator.app"
                    ),
                ]
            )

            runner.start(with: preset)
            XCTAssertEqual(runner.sessionPhase, .active)

            runner.restoreIfPossible()

            XCTAssertEqual(runner.sessionPhase, .restored)
            XCTAssertNil(runner.activeSnapshot)
        }
    }

    func test_restoreSuccess_includesContentCleanupCounts() async {
        await MainActor.run {
            var launcher = MockAppLauncher()
            launcher.openItemsResult = LaunchExecutionResult(
                launchedApplications: ["Calculator"],
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
            var restore = MockRestore()
            restore.restoreResult = RestoreExecutionResult(
                cleanedURLsCount: 2,
                skippedFilesCount: 3
            )
            let runner = makeRunner(launcher: launcher, restore: restore)
            let preset = Preset(
                name: "Test",
                appsToLaunch: [
                    PresetApp(
                        displayName: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        bundlePath: "/System/Applications/Calculator.app"
                    ),
                ]
            )

            runner.start(with: preset)
            runner.restoreIfPossible()

            guard case let .restored(feedback) = runner.lastActionState else {
                return XCTFail("Expected restored feedback")
            }

            XCTAssertEqual(feedback.cleanedURLsCount, 2)
            XCTAssertEqual(feedback.skippedFilesCount, 3)
        }
    }

    // MARK: - Snapshot persistence

    func test_startPersistsSnapshotToDisk() async {
        await MainActor.run {
            var launcher = MockAppLauncher()
            launcher.openItemsResult = LaunchExecutionResult(
                launchedApplications: ["Calculator"],
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
            let runner = makeRunner(launcher: launcher)
            let preset = Preset(
                name: "Test",
                appsToLaunch: [
                    PresetApp(
                        displayName: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        bundlePath: "/System/Applications/Calculator.app"
                    ),
                ]
            )

            runner.start(with: preset)

            XCTAssertTrue(FileManager.default.fileExists(atPath: snapshotStorageURL.path))
        }
    }

    func test_restoreDeletesPersistedSnapshot() async {
        await MainActor.run {
            var launcher = MockAppLauncher()
            launcher.openItemsResult = LaunchExecutionResult(
                launchedApplications: ["Calculator"],
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
            let runner = makeRunner(launcher: launcher)
            let preset = Preset(
                name: "Test",
                appsToLaunch: [
                    PresetApp(
                        displayName: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        bundlePath: "/System/Applications/Calculator.app"
                    ),
                ]
            )

            runner.start(with: preset)
            XCTAssertTrue(FileManager.default.fileExists(atPath: snapshotStorageURL.path))

            runner.restoreIfPossible()
            XCTAssertFalse(FileManager.default.fileExists(atPath: snapshotStorageURL.path))
        }
    }

    // MARK: - Load persisted session

    func test_loadPersistedSession_restoresActiveState() async throws {
        let snapshot = SessionSnapshot(
            id: UUID(),
            presetID: UUID(),
            presetName: "Persisted",
            startedAt: Date(),
            launchedApplications: ["Safari"],
            launchedApplicationBundleIdentifiers: ["com.apple.Safari"],
            openedURLs: [],
            openedFiles: [],
            overlayWasShown: false
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotStorageURL, options: .atomic)

        await MainActor.run {
            let runner = makeRunner()
            runner.loadPersistedSession()

            XCTAssertEqual(runner.sessionPhase, .active)
            XCTAssertNotNil(runner.activeSnapshot)
            XCTAssertEqual(runner.activeSnapshot?.presetName, "Persisted")
        }
    }
}
