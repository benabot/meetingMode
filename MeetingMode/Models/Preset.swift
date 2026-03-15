import Foundation

struct Preset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconSystemName: String
    var appsToLaunch: [String]
    var checklistItems: [ChecklistItem]
    var showsOverlay: Bool
}
