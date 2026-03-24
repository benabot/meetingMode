import XCTest

@testable import MeetingMode

final class AppLauncherServiceTests: XCTestCase {
    func test_openedURLRecord_resolvesTargetBundleIdentifierAndLaunchAttribution() {
        let targetApplicationURL = URL(fileURLWithPath: "/System/Applications/Calculator.app")

        let record = AppLauncherService.openedURLRecord(
            for: "https://example.com",
            targetApplicationURL: targetApplicationURL,
            launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
        )

        XCTAssertEqual(record.url, "https://example.com")
        XCTAssertEqual(record.targetBundleIdentifier, "com.apple.calculator")
        XCTAssertTrue(record.targetWasLaunchedByMeetingMode)
    }

    func test_openedFileRecord_defaultsToNotLaunchedWhenTargetBundleIsNotTracked() {
        let targetApplicationURL = URL(fileURLWithPath: "/System/Applications/Calculator.app")

        let record = AppLauncherService.openedFileRecord(
            for: "/tmp/report.pdf",
            targetApplicationURL: targetApplicationURL,
            launchedApplicationBundleIdentifiers: []
        )

        XCTAssertEqual(record.filePath, "/tmp/report.pdf")
        XCTAssertEqual(record.targetBundleIdentifier, "com.apple.calculator")
        XCTAssertFalse(record.targetWasLaunchedByMeetingMode)
    }

    func test_targetWasLaunchedByMeetingMode_onlyMatchesTrackedBundleIdentifiers() {
        XCTAssertTrue(
            AppLauncherService.targetWasLaunchedByMeetingMode(
                targetBundleIdentifier: "com.apple.calculator",
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
        )

        XCTAssertFalse(
            AppLauncherService.targetWasLaunchedByMeetingMode(
                targetBundleIdentifier: "com.apple.safari",
                launchedApplicationBundleIdentifiers: ["com.apple.calculator"]
            )
        )
    }
}
