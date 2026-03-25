import Foundation

private func defaultTutorialLaunchVersionIdentifier() -> String {
    let bundle = Bundle.main
    let marketingVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    return "\(marketingVersion) (\(buildVersion))"
}

private func defaultTutorialLaunchStateURL() -> URL {
    let fileManager = FileManager.default
    let applicationSupportURL = fileManager.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    ).first ?? fileManager.homeDirectoryForCurrentUser

    return applicationSupportURL
        .appendingPathComponent("MeetingMode", isDirectory: true)
        .appendingPathComponent("tutorial-launch-version.txt")
}

@MainActor
final class TutorialService {
    private let storageURL: URL
    private let launchVersionProvider: () -> String

    init(
        storageURL: URL? = nil,
        launchVersionProvider: (() -> String)? = nil
    ) {
        self.storageURL = storageURL ?? defaultTutorialLaunchStateURL()
        self.launchVersionProvider = launchVersionProvider ?? defaultTutorialLaunchVersionIdentifier
    }

    var shouldShowOnLaunch: Bool {
        storedShownOnLaunchVersion() != launchVersionProvider()
    }

    func markShownOnLaunch() {
        persistShownOnLaunchVersion(launchVersionProvider())
    }

    private func storedShownOnLaunchVersion() -> String? {
        guard let storedVersion = try? String(contentsOf: storageURL, encoding: .utf8) else {
            return nil
        }

        return storedVersion.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func persistShownOnLaunchVersion(_ version: String) {
        let directoryURL = storageURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            try Data(version.utf8).write(to: storageURL, options: .atomic)
        } catch {
            return
        }
    }
}
