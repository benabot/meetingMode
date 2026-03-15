import Combine
import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable

    var isEnabled: Bool {
        self == .enabled
    }

    var detail: String {
        switch self {
        case .enabled:
            return L10n.string(
                "settings.launch_at_login.status.enabled",
                defaultValue: "Meeting Mode launches automatically when you sign in on this Mac."
            )
        case .disabled:
            return L10n.string(
                "settings.launch_at_login.status.disabled",
                defaultValue: "Meeting Mode does not launch automatically when you sign in on this Mac."
            )
        case .requiresApproval:
            return L10n.string(
                "settings.launch_at_login.status.requires_approval",
                defaultValue: "macOS still needs approval in System Settings > General > Login Items."
            )
        case .unavailable:
            return L10n.string(
                "settings.launch_at_login.status.unavailable",
                defaultValue: "This build could not register itself as a login item on this Mac."
            )
        }
    }
}

@MainActor
final class LaunchAtLoginService: ObservableObject {
    @Published private(set) var status: LaunchAtLoginStatus = .disabled

    private let appService: SMAppService

    init(appService: SMAppService = .mainApp) {
        self.appService = appService
        refreshStatus()
    }

    func refreshStatus() {
        status = Self.map(appService.status)
    }

    func setEnabled(_ enabled: Bool) {
        let currentStatus = appService.status

        if enabled, currentStatus == .enabled {
            refreshStatus()
            return
        }

        if !enabled, currentStatus == .notRegistered {
            refreshStatus()
            return
        }

        do {
            if enabled {
                try appService.register()
            } else {
                try appService.unregister()
            }
        } catch {
            // Keep the UI aligned with the real service state after a failed request.
        }

        refreshStatus()
    }

    private static func map(_ status: SMAppService.Status) -> LaunchAtLoginStatus {
        switch status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .disabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }
}
