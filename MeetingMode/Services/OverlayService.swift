import Foundation

@MainActor
final class OverlayService {
    private(set) var isOverlayVisible = false

    func showOverlay() {
        isOverlayVisible = true
    }

    func hideOverlay() {
        isOverlayVisible = false
    }
}
