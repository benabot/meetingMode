import Foundation

private func defaultTutorialLaunchVersionIdentifier() -> String {
    let bundle = Bundle.main
    let marketingVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    return "\(marketingVersion) (\(buildVersion))"
}

@MainActor
final class TutorialService {
    private let defaults: UserDefaults?
    private let launchVersionProvider: () -> String
    private let shownOnLaunchVersionKey = "MeetingMode.tutorial.shownOnLaunchVersion"

    init(
        defaults: UserDefaults? = .standard,
        launchVersionProvider: (() -> String)? = nil
    ) {
        self.defaults = defaults
        self.launchVersionProvider = launchVersionProvider ?? defaultTutorialLaunchVersionIdentifier
    }

    var shouldShowOnLaunch: Bool {
        defaults?.string(forKey: shownOnLaunchVersionKey) != launchVersionProvider()
    }

    func markShownOnLaunch() {
        defaults?.set(launchVersionProvider(), forKey: shownOnLaunchVersionKey)
    }

}
