import XCTest

@testable import MeetingMode

final class TutorialServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "TutorialServiceTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        super.tearDown()
    }

    func test_shouldShowOnLaunch_whenNoVersionStored() async {
        let shouldShowOnLaunch = await MainActor.run {
            let service = TutorialService(
                defaults: defaults,
                launchVersionProvider: { "0.1.1 (2)" }
            )

            return service.shouldShowOnLaunch
        }

        XCTAssertTrue(shouldShowOnLaunch)
    }

    func test_markShownOnLaunch_recordsCurrentVersion() async {
        let result = await MainActor.run {
            let service = TutorialService(
                defaults: defaults,
                launchVersionProvider: { "0.1.1 (2)" }
            )

            service.markShownOnLaunch()

            let storedVersion = defaults.string(forKey: "MeetingMode.tutorial.shownOnLaunchVersion")
            return (storedVersion, service.shouldShowOnLaunch)
        }

        XCTAssertEqual(result.0, "0.1.1 (2)")
        XCTAssertFalse(result.1)
    }

    func test_shouldShowOnLaunch_whenStoredVersionDiffers() async {
        defaults.set("0.1.0 (1)", forKey: "MeetingMode.tutorial.shownOnLaunchVersion")

        let shouldShowOnLaunch = await MainActor.run {
            let service = TutorialService(
                defaults: defaults,
                launchVersionProvider: { "0.1.1 (2)" }
            )

            return service.shouldShowOnLaunch
        }

        XCTAssertTrue(shouldShowOnLaunch)
    }
}
