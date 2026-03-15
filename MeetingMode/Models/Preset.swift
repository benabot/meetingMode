import Foundation

struct PresetApp: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var bundleIdentifier: String?
    var bundlePath: String?

    init(
        id: UUID = UUID(),
        displayName: String,
        bundleIdentifier: String? = nil,
        bundlePath: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.bundlePath = bundlePath
    }

    static func named(_ displayName: String) -> PresetApp {
        PresetApp(displayName: displayName)
    }

    var hasLaunchTarget: Bool {
        normalizedBundleIdentifier != nil
            || normalizedBundlePath != nil
            || !normalizedDisplayName.isEmpty
    }

    var normalizedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedBundleIdentifier: String? {
        let trimmed = bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var normalizedBundlePath: String? {
        let trimmed = bundlePath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var secondaryLabel: String? {
        normalizedBundleIdentifier ?? normalizedBundlePath
    }

    var deduplicationKey: String {
        if let normalizedBundleIdentifier {
            return "bundle-id:\(normalizedBundleIdentifier)"
        }

        if let normalizedBundlePath {
            return "bundle-path:\(normalizedBundlePath)"
        }

        return "name:\(normalizedDisplayName.lowercased())"
    }
}

struct Preset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconSystemName: String
    var appsToLaunch: [PresetApp]
    var urlsToOpen: [String]
    var filesToOpen: [String]
    var checklistItems: [ChecklistItem]
    var showsOverlay: Bool

    init(
        id: UUID = UUID(),
        name: String,
        iconSystemName: String = "sparkles",
        appsToLaunch: [PresetApp] = [],
        urlsToOpen: [String] = [],
        filesToOpen: [String] = [],
        checklistItems: [ChecklistItem] = [],
        showsOverlay: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconSystemName = iconSystemName
        self.appsToLaunch = appsToLaunch
        self.urlsToOpen = urlsToOpen
        self.filesToOpen = filesToOpen
        self.checklistItems = checklistItems
        self.showsOverlay = showsOverlay
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconSystemName
        case appsToLaunch
        case urlsToOpen
        case filesToOpen
        case checklistItems
        case showsOverlay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        iconSystemName = try container.decodeIfPresent(String.self, forKey: .iconSystemName) ?? "sparkles"
        if let decodedApps = try? container.decode([PresetApp].self, forKey: .appsToLaunch) {
            appsToLaunch = decodedApps.filter(\.hasLaunchTarget)
        } else {
            let legacyApps = try container.decodeIfPresent([String].self, forKey: .appsToLaunch) ?? []
            appsToLaunch = legacyApps
                .map { PresetApp.named($0) }
                .filter(\.hasLaunchTarget)
        }
        urlsToOpen = try container.decodeIfPresent([String].self, forKey: .urlsToOpen) ?? []
        filesToOpen = try container.decodeIfPresent([String].self, forKey: .filesToOpen) ?? []
        checklistItems = try container.decodeIfPresent([ChecklistItem].self, forKey: .checklistItems) ?? []
        showsOverlay = try container.decodeIfPresent(Bool.self, forKey: .showsOverlay) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(iconSystemName, forKey: .iconSystemName)
        try container.encode(appsToLaunch, forKey: .appsToLaunch)
        try container.encode(urlsToOpen, forKey: .urlsToOpen)
        try container.encode(filesToOpen, forKey: .filesToOpen)
        try container.encode(checklistItems, forKey: .checklistItems)
        try container.encode(showsOverlay, forKey: .showsOverlay)
    }

    var hasStartableActions: Bool {
        configuredStartableActionCount > 0
    }

    var configuredStartableActionCount: Int {
        configuredAppsCount
            + nonEmptyCount(in: urlsToOpen)
            + nonEmptyCount(in: filesToOpen)
            + (showsOverlay ? 1 : 0)
    }

    private var configuredAppsCount: Int {
        appsToLaunch.reduce(into: 0) { count, app in
            if app.hasLaunchTarget {
                count += 1
            }
        }
    }

    private func nonEmptyCount(in values: [String]) -> Int {
        values.reduce(into: 0) { count, value in
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                count += 1
            }
        }
    }
}
