import AppKit
import SwiftUI

@MainActor
final class OverlayService: OverlayProviding {
    private let appLanguageService: AppLanguageService
    private(set) var isOverlayVisible = false
    private var overlayWindows: [NSWindow] = []

    init(appLanguageService: AppLanguageService) {
        self.appLanguageService = appLanguageService
    }

    func showOverlay() -> Bool {
        if isOverlayVisible {
            for window in overlayWindows {
                window.orderFrontRegardless()
            }
            return true
        }

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return false
        }

        var createdWindows: [NSWindow] = []

        for screen in screens {
            let overlayFrame = screen.visibleFrame
            guard !overlayFrame.isEmpty else { continue }

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
            // Keep the clean screen as a visual background complement. Session clarity
            // should come from app visibility, not from per-app window-level exceptions.
            window.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
            window.collectionBehavior = [.moveToActiveSpace]
            window.animationBehavior = .none
            window.contentView = NSHostingView(
                rootView: CleanScreenOverlayView(appLanguageService: appLanguageService)
            )

            window.orderFrontRegardless()
            createdWindows.append(window)
        }

        guard !createdWindows.isEmpty else {
            return false
        }

        overlayWindows = createdWindows
        isOverlayVisible = true
        return true
    }

    func hideOverlay() -> Bool {
        guard !overlayWindows.isEmpty else {
            isOverlayVisible = false
            return false
        }

        for window in overlayWindows {
            window.orderOut(nil)
            window.close()
        }
        overlayWindows = []
        isOverlayVisible = false
        return true
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
