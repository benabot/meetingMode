import Foundation

struct SessionSnapshot: Identifiable, Codable, Hashable {
    let id: UUID
    let presetID: UUID
    var presetName: String
    var startedAt: Date
    var launchedApplications: [String]
    var launchedApplicationBundleIdentifiers: [String]
    var openedURLs: [String]
    var openedFiles: [String]
    var overlayWasShown: Bool

    init(
        id: UUID,
        presetID: UUID,
        presetName: String,
        startedAt: Date,
        launchedApplications: [String],
        launchedApplicationBundleIdentifiers: [String] = [],
        openedURLs: [String],
        openedFiles: [String],
        overlayWasShown: Bool
    ) {
        self.id = id
        self.presetID = presetID
        self.presetName = presetName
        self.startedAt = startedAt
        self.launchedApplications = launchedApplications
        self.launchedApplicationBundleIdentifiers = launchedApplicationBundleIdentifiers
        self.openedURLs = openedURLs
        self.openedFiles = openedFiles
        self.overlayWasShown = overlayWasShown
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case presetID
        case presetName
        case startedAt
        case launchedApplications
        case launchedApplicationBundleIdentifiers
        case openedURLs
        case openedFiles
        case overlayWasShown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        presetID = try container.decode(UUID.self, forKey: .presetID)
        presetName = try container.decode(String.self, forKey: .presetName)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        launchedApplications = try container.decodeIfPresent([String].self, forKey: .launchedApplications) ?? []
        launchedApplicationBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .launchedApplicationBundleIdentifiers) ?? []
        openedURLs = try container.decodeIfPresent([String].self, forKey: .openedURLs) ?? []
        openedFiles = try container.decodeIfPresent([String].self, forKey: .openedFiles) ?? []
        overlayWasShown = try container.decodeIfPresent(Bool.self, forKey: .overlayWasShown) ?? false
    }

    var appliedActionCount: Int {
        launchedApplications.count
            + openedURLs.count
            + openedFiles.count
            + (overlayWasShown ? 1 : 0)
    }

    var restorableApplicationCount: Int {
        Set(launchedApplicationBundleIdentifiers).count
    }
}
