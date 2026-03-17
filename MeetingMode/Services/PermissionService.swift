import Combine
import Foundation

enum PermissionStatus {
    case notChecked
    case notRequired

    var title: String {
        switch self {
        case .notChecked:
            return L10n.string(
                "permissions.status.not_checked",
                defaultValue: "Not checked"
            )
        case .notRequired:
            return L10n.string(
                "permissions.status.not_required",
                defaultValue: "Not required"
            )
        }
    }

    var detail: String {
        switch self {
        case .notChecked:
            return L10n.string(
                "permissions.status.not_checked.detail",
                defaultValue: "Meeting Mode does not inspect or request this permission yet."
            )
        case .notRequired:
            return L10n.string(
                "permissions.status.not_required.detail",
                defaultValue: "This permission is not required by the current implementation."
            )
        }
    }
}

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var accessibilityStatus: PermissionStatus = .notRequired
    @Published private(set) var automationStatus: PermissionStatus = .notRequired
    @Published private(set) var screenRecordingStatus: PermissionStatus = .notRequired

    init() {
        refreshStatuses()
    }

    var shortSummary: String {
        L10n.string(
            "permissions.summary.none_required",
            defaultValue: "No macOS permissions are required by the current implementation."
        )
    }

    func refreshStatuses() {
        accessibilityStatus = .notRequired
        automationStatus = .notRequired
        screenRecordingStatus = .notRequired
    }
}
