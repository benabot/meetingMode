import Combine
import Foundation

enum PermissionStatus {
    case notChecked

    var title: String {
        switch self {
        case .notChecked:
            return L10n.string(
                "permissions.status.not_checked",
                defaultValue: "Not checked"
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
        }
    }
}

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var accessibilityStatus: PermissionStatus = .notChecked
    @Published private(set) var automationStatus: PermissionStatus = .notChecked
    @Published private(set) var screenRecordingStatus: PermissionStatus = .notChecked

    init() {
        refreshStatuses()
    }

    var shortSummary: String {
        L10n.string(
            "permissions.summary.none_checked",
            defaultValue: "No macOS permissions are checked or requested yet."
        )
    }

    func refreshStatuses() {
        accessibilityStatus = .notChecked
        automationStatus = .notChecked
        screenRecordingStatus = .notChecked
    }
}
