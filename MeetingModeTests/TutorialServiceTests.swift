import XCTest

@testable import MeetingMode

final class TutorialServiceTests: XCTestCase {
    private var storageURL: URL!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TutorialServiceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        storageURL = tempDirectory.appendingPathComponent("tutorial-launch-version.txt")
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        storageURL = nil
        super.tearDown()
    }

    func test_shouldShowOnLaunch_whenNoVersionStored() async {
        let shouldShowOnLaunch = await MainActor.run {
            let service = TutorialService(
                storageURL: storageURL,
                launchVersionProvider: { "0.1.1 (2)" }
            )

            return service.shouldShowOnLaunch
        }

        XCTAssertTrue(shouldShowOnLaunch)
    }

    func test_markShownOnLaunch_recordsCurrentVersion() async {
        let result = await MainActor.run {
            let service = TutorialService(
                storageURL: storageURL,
                launchVersionProvider: { "0.1.1 (2)" }
            )

            service.markShownOnLaunch()

            let storedVersion = try? String(contentsOf: storageURL, encoding: .utf8)
            return (storedVersion, service.shouldShowOnLaunch)
        }

        XCTAssertEqual(result.0, "0.1.1 (2)")
        XCTAssertFalse(result.1)
    }

    func test_shouldShowOnLaunch_whenStoredVersionDiffers() async {
        try? Data("0.1.0 (1)".utf8).write(to: storageURL, options: .atomic)

        let shouldShowOnLaunch = await MainActor.run {
            let service = TutorialService(
                storageURL: storageURL,
                launchVersionProvider: { "0.1.1 (2)" }
            )

            return service.shouldShowOnLaunch
        }

        XCTAssertTrue(shouldShowOnLaunch)
    }
}
