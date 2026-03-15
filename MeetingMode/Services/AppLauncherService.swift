import Foundation

@MainActor
final class AppLauncherService {
    func launchApplications(for preset: Preset) -> [String] {
        // Real launch automation is intentionally deferred until the permission
        // and restore flows are implemented.
        preset.appsToLaunch
    }

    func restoreApplications(from snapshot: SessionSnapshot) {
        _ = snapshot
    }
}
