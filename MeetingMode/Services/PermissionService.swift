import Combine
import Foundation

enum PermissionStatus: String {
    case scaffold = "Scaffold"
    case pendingUserGrant = "Pending"
    case granted = "Granted"

    var detail: String {
        switch self {
        case .scaffold:
            return "Not implemented yet in this technical base."
        case .pendingUserGrant:
            return "Will require explicit user consent when wired."
        case .granted:
            return "Available."
        }
    }
}

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var accessibilityStatus: PermissionStatus = .scaffold
    @Published private(set) var automationStatus: PermissionStatus = .scaffold
    @Published private(set) var screenRecordingStatus: PermissionStatus = .scaffold

    var shortSummary: String {
        "Permissions remain stubbed until automation is implemented."
    }

    func refreshStatuses() {
        accessibilityStatus = .scaffold
        automationStatus = .scaffold
        screenRecordingStatus = .scaffold
    }
}
