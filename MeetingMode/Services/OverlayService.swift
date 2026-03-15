import AppKit
import SwiftUI

@MainActor
final class OverlayService {
    private(set) var isOverlayVisible = false
    private var overlayWindow: NSWindow?

    func showOverlay() -> Bool {
        if isOverlayVisible {
            overlayWindow?.orderFrontRegardless()
            return true
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return false
        }

        let overlayFrame = screen.visibleFrame
        guard !overlayFrame.isEmpty else {
            return false
        }

        let window = OverlayWindow(
            contentRect: overlayFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.hidesOnDeactivate = false
        window.level = .mainMenu
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        window.animationBehavior = .none
        window.contentView = NSHostingView(rootView: CleanScreenOverlayView())

        window.orderFrontRegardless()

        overlayWindow = window
        isOverlayVisible = true
        return true
    }

    func hideOverlay() -> Bool {
        guard let window = overlayWindow else {
            isOverlayVisible = false
            return false
        }

        window.orderOut(nil)
        window.close()
        overlayWindow = nil
        isOverlayVisible = false
        return true
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
