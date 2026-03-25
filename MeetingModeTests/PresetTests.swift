import XCTest

@testable import MeetingMode

final class PresetTests: XCTestCase {
    func test_presetDecodesLegacyShowsOverlayAsSolidBackground() throws {
        let payload: [String: Any] = [
            "id": UUID().uuidString,
            "name": "Legacy",
            "iconSystemName": "sparkles",
            "appsToLaunch": [],
            "urlsToOpen": [],
            "filesToOpen": [],
            "checklistItems": [],
            "showsOverlay": true
        ]

        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        let preset = try JSONDecoder().decode(Preset.self, from: data)

        XCTAssertEqual(preset.presentationBackground.mode, .solidColor)
        XCTAssertTrue(preset.showsOverlay)
        XCTAssertTrue(preset.hasStartableActions)
    }

    func test_presetDecodesLegacyShowsOverlayFalseAsNone() throws {
        let payload: [String: Any] = [
            "id": UUID().uuidString,
            "name": "Legacy",
            "iconSystemName": "sparkles",
            "appsToLaunch": [],
            "urlsToOpen": [],
            "filesToOpen": [],
            "checklistItems": [],
            "showsOverlay": false
        ]

        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        let preset = try JSONDecoder().decode(Preset.self, from: data)

        XCTAssertEqual(preset.presentationBackground.mode, .none)
        XCTAssertFalse(preset.showsOverlay)
        XCTAssertFalse(preset.hasStartableActions)
    }

    func test_presetEncodesAndDecodesPresentationBackground() throws {
        let background = PresentationBackground.image(
            path: "/Users/benoitabot/Pictures/background.png",
            solidColor: PresentationBackgroundColor(red: 0.12, green: 0.13, blue: 0.14),
            opacity: 0.78
        )
        let preset = Preset(
            name: "Demo",
            presentationBackground: background
        )

        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(Preset.self, from: data)

        XCTAssertEqual(decoded.presentationBackground.mode, .image)
        XCTAssertEqual(decoded.presentationBackground.imagePath, background.imagePath)
        XCTAssertEqual(decoded.presentationBackground.solidColor, background.solidColor)
        XCTAssertEqual(decoded.presentationBackground.opacity, background.opacity)
    }

    func test_presentationBackgroundStartabilityReflectsMode() {
        XCTAssertFalse(Preset(name: "Empty").hasStartableActions)
        XCTAssertTrue(Preset(name: "Solid", presentationBackground: .solidColor()).hasStartableActions)
        XCTAssertTrue(
            Preset(
                name: "Image",
                presentationBackground: .image(path: "/tmp/background.png")
            ).hasStartableActions
        )
        XCTAssertFalse(
            Preset(
                name: "Invalid image",
                presentationBackground: .image(path: "")
            ).hasStartableActions
        )
    }
}
