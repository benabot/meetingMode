import Combine
import Foundation

enum PermissionStatus: String {
    case notChecked = "Not checked"

    var detail: String {
        "Meeting Mode does not inspect or request this permission yet."
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
        "No macOS permissions are checked or requested yet."
    }

    func refreshStatuses() {
        accessibilityStatus = .notChecked
        automationStatus = .notChecked
        screenRecordingStatus = .notChecked
    }
}
