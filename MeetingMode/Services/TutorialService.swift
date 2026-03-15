import Foundation

@MainActor
final class TutorialService {
    private let defaults: UserDefaults?
    private let hasShownOnLaunchKey = "MeetingMode.tutorial.hasShownOnLaunch"

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
    }

    var shouldShowOnLaunch: Bool {
        !(defaults?.bool(forKey: hasShownOnLaunchKey) ?? false)
    }

    func markShownOnLaunch() {
        defaults?.set(true, forKey: hasShownOnLaunchKey)
    }
}
