import Combine
import Foundation

@MainActor
final class PresetStore: ObservableObject {
    @Published var presets: [Preset]
    @Published var selectedPresetID: Preset.ID?

    private let storageURL: URL

    init(presets: [Preset]? = nil, storageURL: URL? = nil) {
        let storageURL = storageURL ?? Self.defaultStorageURL()
        self.storageURL = storageURL

        let presets = presets ?? Self.loadPresets(from: storageURL)
        self.presets = presets
        self.selectedPresetID = presets.first?.id
    }

    var hasPresets: Bool {
        !presets.isEmpty
    }

    var selectedPreset: Preset? {
        guard let selectedPresetID else {
            return presets.first
        }

        return presets.first { $0.id == selectedPresetID }
    }

    private static func loadPresets(from storageURL: URL) -> [Preset] {
        let fileManager = FileManager.default

        do {
            let directoryURL = storageURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            return []
        }

        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: storageURL)
            if data.isEmpty {
                return []
            }

            return try JSONDecoder().decode([Preset].self, from: data)
        } catch {
            return []
        }
    }

    private static func defaultStorageURL() -> URL {
        let fileManager = FileManager.default
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser

        return applicationSupportURL
            .appendingPathComponent("MeetingMode", isDirectory: true)
            .appendingPathComponent("presets.json")
    }
}
