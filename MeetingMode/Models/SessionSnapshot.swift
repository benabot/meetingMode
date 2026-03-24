import Foundation

struct HiddenApplicationSnapshot: Codable, Hashable {
    let bundleIdentifier: String
    let processIdentifier: Int32
    let localizedName: String
    let bundlePath: String?

    init(
        bundleIdentifier: String,
        processIdentifier: Int32,
        localizedName: String,
        bundlePath: String? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.localizedName = localizedName
        self.bundlePath = bundlePath
    }
}

struct OpenedURLRecord: Codable, Hashable {
    let url: String
    let targetBundleIdentifier: String?
    let targetWasLaunchedByMeetingMode: Bool

    init(
        url: String,
        targetBundleIdentifier: String? = nil,
        targetWasLaunchedByMeetingMode: Bool = false
    ) {
        self.url = url
        self.targetBundleIdentifier = targetBundleIdentifier
        self.targetWasLaunchedByMeetingMode = targetWasLaunchedByMeetingMode
    }
}

struct OpenedFileRecord: Codable, Hashable {
    let filePath: String
    let targetBundleIdentifier: String?
    let targetWasLaunchedByMeetingMode: Bool

    init(
        filePath: String,
        targetBundleIdentifier: String? = nil,
        targetWasLaunchedByMeetingMode: Bool = false
    ) {
        self.filePath = filePath
        self.targetBundleIdentifier = targetBundleIdentifier
        self.targetWasLaunchedByMeetingMode = targetWasLaunchedByMeetingMode
    }
}

struct SessionSnapshot: Identifiable, Codable, Hashable {
    let id: UUID
    let presetID: UUID
    var presetName: String
    var startedAt: Date
    var launchedApplications: [String]
    var launchedApplicationBundleIdentifiers: [String]
    var hiddenApplications: [HiddenApplicationSnapshot]
    var openedURLs: [OpenedURLRecord]
    var openedFiles: [OpenedFileRecord]
    var overlayWasShown: Bool

    init(
        id: UUID,
        presetID: UUID,
        presetName: String,
        startedAt: Date,
        launchedApplications: [String],
        launchedApplicationBundleIdentifiers: [String] = [],
        hiddenApplications: [HiddenApplicationSnapshot] = [],
        openedURLs: [OpenedURLRecord],
        openedFiles: [OpenedFileRecord],
        overlayWasShown: Bool
    ) {
        self.id = id
        self.presetID = presetID
        self.presetName = presetName
        self.startedAt = startedAt
        self.launchedApplications = launchedApplications
        self.launchedApplicationBundleIdentifiers = launchedApplicationBundleIdentifiers
        self.hiddenApplications = hiddenApplications
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
        case hiddenApplications
        case hiddenApplicationBundleIdentifiers
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
        if let hiddenApplications = try container.decodeIfPresent([HiddenApplicationSnapshot].self, forKey: .hiddenApplications) {
            self.hiddenApplications = hiddenApplications
        } else {
            let legacyBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .hiddenApplicationBundleIdentifiers) ?? []
            self.hiddenApplications = legacyBundleIdentifiers.map {
                HiddenApplicationSnapshot(
                    bundleIdentifier: $0,
                    processIdentifier: 0,
                    localizedName: $0
                )
            }
        }
        if let decodedOpenedURLs = try? container.decode([OpenedURLRecord].self, forKey: .openedURLs) {
            openedURLs = decodedOpenedURLs
        } else {
            let legacyOpenedURLs = try container.decodeIfPresent([String].self, forKey: .openedURLs) ?? []
            openedURLs = legacyOpenedURLs.map { OpenedURLRecord(url: $0) }
        }

        if let decodedOpenedFiles = try? container.decode([OpenedFileRecord].self, forKey: .openedFiles) {
            openedFiles = decodedOpenedFiles
        } else {
            let legacyOpenedFiles = try container.decodeIfPresent([String].self, forKey: .openedFiles) ?? []
            openedFiles = legacyOpenedFiles.map { OpenedFileRecord(filePath: $0) }
        }
        overlayWasShown = try container.decodeIfPresent(Bool.self, forKey: .overlayWasShown) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(presetID, forKey: .presetID)
        try container.encode(presetName, forKey: .presetName)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(launchedApplications, forKey: .launchedApplications)
        try container.encode(launchedApplicationBundleIdentifiers, forKey: .launchedApplicationBundleIdentifiers)
        try container.encode(hiddenApplications, forKey: .hiddenApplications)
        try container.encode(openedURLs, forKey: .openedURLs)
        try container.encode(openedFiles, forKey: .openedFiles)
        try container.encode(overlayWasShown, forKey: .overlayWasShown)
    }

    var appliedActionCount: Int {
        launchedApplications.count
            + hiddenApplicationCount
            + openedURLs.count
            + openedFiles.count
            + (overlayWasShown ? 1 : 0)
    }

    var restorableApplicationCount: Int {
        Set(launchedApplicationBundleIdentifiers)
            .union(hiddenApplications.map(\.bundleIdentifier))
            .count
    }

    var hiddenApplicationCount: Int {
        hiddenApplications.count
    }
}
