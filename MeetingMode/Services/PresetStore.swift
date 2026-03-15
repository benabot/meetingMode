import Combine
import Foundation

@MainActor
final class PresetStore: ObservableObject {
    @Published var presets: [Preset]
    @Published var selectedPresetID: Preset.ID?

    init(presets: [Preset] = Preset.samples) {
        self.presets = presets
        self.selectedPresetID = presets.first?.id
    }

    var selectedPreset: Preset? {
        guard let selectedPresetID else {
            return presets.first
        }

        return presets.first { $0.id == selectedPresetID }
    }
}
