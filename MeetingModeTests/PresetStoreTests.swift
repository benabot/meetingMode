import XCTest

@testable import MeetingMode

@MainActor
final class PresetStoreTests: XCTestCase {
    private var tempDirectory: URL!
    private var storageURL: URL!
    private var selectionDefaults: UserDefaults!
    private var selectionSuiteName: String!

    override func setUp() {
        super.setUp()
        let uniqueID = UUID().uuidString
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PresetStoreTests-\(uniqueID)", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        storageURL = tempDirectory.appendingPathComponent("presets.json")

        selectionSuiteName = "PresetStoreTests-\(uniqueID)"
        selectionDefaults = UserDefaults(suiteName: selectionSuiteName)
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        if let suiteName = selectionSuiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        selectionDefaults = nil
        super.tearDown()
    }

    // MARK: - Seed behavior

    func test_missingFile_seedsQuickTest() {
        let store = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )

        XCTAssertEqual(store.presets.count, 1)
        XCTAssertEqual(store.presets.first?.name, "Quick Test")
        XCTAssertEqual(
            store.presets.first?.appsToLaunch.first?.bundleIdentifier,
            "com.apple.calculator"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))
    }

    // MARK: - Empty array

    func test_emptyArray_keepsEmpty() throws {
        try Data("[]".utf8).write(to: storageURL, options: .atomic)

        let store = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )

        XCTAssertEqual(store.presets.count, 0)
        XCTAssertNil(store.selectedPresetID)
    }

    // MARK: - Invalid JSON

    func test_invalidJSON_fallsToEmpty() throws {
        try Data("not json".utf8).write(to: storageURL, options: .atomic)

        let store = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )

        XCTAssertEqual(store.presets.count, 0)
    }

    // MARK: - Add and persist

    func test_addPreset_persistsToFile() throws {
        let store = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )

        let preset = Preset(
            name: "Demo",
            appsToLaunch: [
                PresetApp(
                    displayName: "Safari",
                    bundleIdentifier: "com.apple.Safari",
                    bundlePath: "/Applications/Safari.app"
                ),
            ],
            showsOverlay: true
        )
        store.addPreset(preset)

        let data = try Data(contentsOf: storageURL)
        let decoded = try JSONDecoder().decode([Preset].self, from: data)
        XCTAssertTrue(decoded.contains(where: { $0.name == "Demo" }))
    }

    // MARK: - Delete and selection fallback

    func test_deleteSelectedPreset_fallsBackToNext() throws {
        let presetA = Preset(name: "A", showsOverlay: true)
        let presetB = Preset(name: "B", showsOverlay: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode([presetA, presetB])
        try data.write(to: storageURL, options: .atomic)

        let store = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )

        store.selectPreset(presetA.id)
        XCTAssertEqual(store.selectedPresetID, presetA.id)

        store.deletePreset(presetA)
        XCTAssertEqual(store.selectedPresetID, presetB.id)
    }

    // MARK: - Selection survives new instance

    func test_selectedPresetID_survivesNewInstance() throws {
        let presetA = Preset(name: "A", showsOverlay: true)
        let presetB = Preset(name: "B", showsOverlay: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode([presetA, presetB])
        try data.write(to: storageURL, options: .atomic)

        let store1 = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )
        store1.selectPreset(presetB.id)

        let store2 = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )

        XCTAssertEqual(store2.selectedPresetID, presetB.id)
    }

    // MARK: - Legacy migration

    func test_legacyTextEdit_migratedToCalculator() throws {
        let legacyPreset = Preset(
            name: "Quick Test",
            iconSystemName: "bolt.circle.fill",
            appsToLaunch: [
                PresetApp(
                    displayName: "TextEdit",
                    bundleIdentifier: "com.apple.TextEdit",
                    bundlePath: "/System/Applications/TextEdit.app"
                ),
            ],
            checklistItems: [
                ChecklistItem(title: "Confirm the menu bar icon turns red"),
                ChecklistItem(
                    title: "Use Restore Session to hide clean screen and quit TextEdit"
                ),
            ],
            showsOverlay: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode([legacyPreset])
        try data.write(to: storageURL, options: .atomic)

        let store = PresetStore(
            storageURL: storageURL,
            selectionDefaults: selectionDefaults
        )

        XCTAssertEqual(store.presets.count, 1)
        XCTAssertEqual(
            store.presets.first?.appsToLaunch.first?.bundleIdentifier,
            "com.apple.calculator"
        )
        XCTAssertEqual(
            store.presets.first?.appsToLaunch.first?.displayName,
            "Calculator"
        )
    }

    // MARK: - hasStartableActions

    func test_presetWithNoActions_isNotStartable() {
        let preset = Preset(
            name: "Empty",
            checklistItems: [
                ChecklistItem(title: "Check mic"),
            ]
        )

        XCTAssertFalse(preset.hasStartableActions)
    }
}
