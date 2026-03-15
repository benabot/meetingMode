import Combine
import Foundation

@MainActor
final class PresetStore: ObservableObject {
    @Published var presets: [Preset]
    @Published private(set) var selectedPresetID: Preset.ID?

    private let storageURL: URL
    private let selectionDefaults: UserDefaults?
    private let selectionDefaultsKey = "MeetingMode.selectedPresetID"

    init(
        presets: [Preset]? = nil,
        storageURL: URL? = nil,
        selectionDefaults: UserDefaults? = .standard
    ) {
        let storageURL = storageURL ?? Self.defaultStorageURL()
        self.storageURL = storageURL
        self.selectionDefaults = selectionDefaults

        let loadResult = presets.map(LoadResult.loaded) ?? Self.loadPresets(from: storageURL)
        let initialPresets: [Preset]

        switch loadResult {
        case .missing:
            initialPresets = Self.seedPresets()
        case .loaded(let loadedPresets):
            initialPresets = loadedPresets
        case .invalid:
            initialPresets = []
        }

        self.presets = initialPresets
        self.selectedPresetID = Self.loadSelectedPresetID(
            from: selectionDefaults,
            key: selectionDefaultsKey
        ) ?? initialPresets.first?.id
        normalizeSelection()

        if case .missing = loadResult {
            persistPresets()
        } else {
            persistSelection()
        }
    }

    var hasPresets: Bool {
        !presets.isEmpty
    }

    var selectedPreset: Preset? {
        if let selectedPresetID,
           let selectedPreset = presets.first(where: { $0.id == selectedPresetID }) {
            return selectedPreset
        }

        return presets.first
    }

    func selectPreset(_ presetID: Preset.ID?) {
        selectedPresetID = presetID
        normalizeSelection()
        persistSelection()
    }

    func addPreset(_ preset: Preset) {
        presets.append(preset)
        selectedPresetID = preset.id
        persistPresets()
    }

    func updatePreset(_ preset: Preset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else {
            return
        }

        presets[index] = preset
        selectedPresetID = preset.id
        persistPresets()
    }

    func deletePreset(_ preset: Preset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else {
            return
        }

        let deletedSelectedPreset = selectedPresetID == preset.id
        presets.remove(at: index)

        if presets.isEmpty {
            selectedPresetID = nil
        } else if deletedSelectedPreset {
            let fallbackIndex = min(index, presets.count - 1)
            selectedPresetID = presets[fallbackIndex].id
        }

        persistPresets()
    }

    private static func loadPresets(from storageURL: URL) -> LoadResult {
        let fileManager = FileManager.default

        do {
            let directoryURL = storageURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            return .invalid
        }

        guard fileManager.fileExists(atPath: storageURL.path) else {
            return .missing
        }

        do {
            let data = try Data(contentsOf: storageURL)
            if data.isEmpty {
                return .loaded([])
            }

            return .loaded(try JSONDecoder().decode([Preset].self, from: data))
        } catch {
            return .invalid
        }
    }

    private static func defaultStorageURL() -> URL {
        let fileManager = FileManager.default
        let legacySandboxURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/fr.beabot.meetingmode/Data/Library/Application Support/MeetingMode/presets.json")
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser
        let currentURL = applicationSupportURL
            .appendingPathComponent("MeetingMode", isDirectory: true)
            .appendingPathComponent("presets.json")

        if fileManager.fileExists(atPath: legacySandboxURL.path),
           !fileManager.fileExists(atPath: currentURL.path) {
            return legacySandboxURL
        }

        return currentURL
    }

    private static func seedPresets() -> [Preset] {
        [
            Preset(
                name: "Quick Test",
                iconSystemName: "bolt.circle.fill",
                appsToLaunch: [
                    PresetApp(
                        displayName: "TextEdit",
                        bundleIdentifier: "com.apple.TextEdit",
                        bundlePath: "/System/Applications/TextEdit.app"
                    ),
                ],
                urlsToOpen: [],
                filesToOpen: [],
                checklistItems: [
                    ChecklistItem(title: "Confirm the menu bar icon turns red"),
                    ChecklistItem(title: "Use Restore Session to hide clean screen and quit TextEdit"),
                ],
                showsOverlay: true
            ),
        ]
    }

    private func persistPresets() {
        normalizeSelection()

        do {
            let directoryURL = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(presets)
            try data.write(to: storageURL, options: .atomic)
            persistSelection()
        } catch {
            assertionFailure("Failed to persist presets: \(error)")
        }
    }

    private func normalizeSelection() {
        guard let selectedPresetID else {
            self.selectedPresetID = presets.first?.id
            return
        }

        if !presets.contains(where: { $0.id == selectedPresetID }) {
            self.selectedPresetID = presets.first?.id
        }
    }

    private func persistSelection() {
        guard let selectionDefaults else {
            return
        }

        if let selectedPresetID {
            selectionDefaults.set(selectedPresetID.uuidString, forKey: selectionDefaultsKey)
        } else {
            selectionDefaults.removeObject(forKey: selectionDefaultsKey)
        }
    }

    private static func loadSelectedPresetID(from defaults: UserDefaults?, key: String) -> UUID? {
        guard let value = defaults?.string(forKey: key) else {
            return nil
        }

        return UUID(uuidString: value)
    }
}

private enum LoadResult {
    case missing
    case loaded([Preset])
    case invalid
}
