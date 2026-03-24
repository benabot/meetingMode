import XCTest

@testable import MeetingMode

final class SessionSnapshotTests: XCTestCase {
    func test_sessionSnapshotDecodesLegacyStringContentWithoutCrashing() throws {
        let snapshotID = UUID()
        let presetID = UUID()
        let startedAt = Date(timeIntervalSinceReferenceDate: 12345)

        let legacyPayload: [String: Any] = [
            "id": snapshotID.uuidString,
            "presetID": presetID.uuidString,
            "presetName": "Legacy",
            "startedAt": startedAt.timeIntervalSinceReferenceDate,
            "launchedApplications": ["Safari"],
            "launchedApplicationBundleIdentifiers": ["com.apple.Safari"],
            "hiddenApplications": [],
            "openedURLs": ["https://example.com"],
            "openedFiles": ["/tmp/report.pdf"],
            "overlayWasShown": true
        ]

        let data = try JSONSerialization.data(withJSONObject: legacyPayload, options: [])
        let decoder = JSONDecoder()
        let snapshot = try decoder.decode(SessionSnapshot.self, from: data)

        XCTAssertEqual(snapshot.id, snapshotID)
        XCTAssertEqual(snapshot.presetID, presetID)
        XCTAssertEqual(snapshot.openedURLs.count, 1)
        XCTAssertEqual(snapshot.openedURLs.first?.url, "https://example.com")
        XCTAssertNil(snapshot.openedURLs.first?.targetBundleIdentifier)
        XCTAssertFalse(snapshot.openedURLs.first?.targetWasLaunchedByMeetingMode ?? true)
        XCTAssertEqual(snapshot.openedFiles.count, 1)
        XCTAssertEqual(snapshot.openedFiles.first?.filePath, "/tmp/report.pdf")
        XCTAssertNil(snapshot.openedFiles.first?.targetBundleIdentifier)
        XCTAssertFalse(snapshot.openedFiles.first?.targetWasLaunchedByMeetingMode ?? true)
        XCTAssertTrue(snapshot.overlayWasShown)
    }
}
