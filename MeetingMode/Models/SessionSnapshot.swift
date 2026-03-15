import Foundation

struct SessionSnapshot: Identifiable, Codable, Hashable {
    let id: UUID
    let presetID: UUID
    var presetName: String
    var startedAt: Date
    var launchedApplications: [String]
    var overlayWasShown: Bool
}
