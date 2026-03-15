import AppKit
import Combine
import SwiftUI

@main
struct MeetingModeApp: App {
    @NSApplicationDelegateAdaptor(MeetingModeAppDelegate.self) private var appDelegate
    @StateObject private var presetStore: PresetStore
    @StateObject private var permissionService: PermissionService
    @StateObject private var sessionRunner: SessionRunner

    init() {
        let presetStore = PresetStore()
        let overlayService = OverlayService()
        let appLauncherService = AppLauncherService()
        let restoreService = RestoreService(
            overlayService: overlayService,
            appLauncherService: appLauncherService
        )
        let permissionService = PermissionService()
        let sessionRunner = SessionRunner(
            appLauncherService: appLauncherService,
            overlayService: overlayService,
            restoreService: restoreService
        )

        _presetStore = StateObject(wrappedValue: presetStore)
        _permissionService = StateObject(wrappedValue: permissionService)
        _sessionRunner = StateObject(wrappedValue: sessionRunner)

        MeetingModeAppDelegate.dependencies = .init(
            presetStore: presetStore,
            sessionRunner: sessionRunner,
            permissionService: permissionService
        )
    }

    var body: some Scene {
        Settings {
            SettingsView(permissionService: permissionService)
        }
    }
}

@MainActor
final class MeetingModeAppDelegate: NSObject, NSApplicationDelegate {
    struct Dependencies {
        let presetStore: PresetStore
        let sessionRunner: SessionRunner
        let permissionService: PermissionService
    }

    static var dependencies: Dependencies?

    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let dependencies = Self.dependencies else {
            return
        }

        statusBarController = StatusBarController(
            presetStore: dependencies.presetStore,
            sessionRunner: dependencies.sessionRunner,
            permissionService: dependencies.permissionService
        )
    }
}

@MainActor
private final class StatusBarController: NSObject {
    private let presetStore: PresetStore
    private let sessionRunner: SessionRunner
    private let permissionService: PermissionService
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private lazy var settingsWindowController = SettingsWindowController(
        permissionService: permissionService
    )
    private var sessionPhaseCancellable: AnyCancellable?

    init(
        presetStore: PresetStore,
        sessionRunner: SessionRunner,
        permissionService: PermissionService
    ) {
        self.presetStore = presetStore
        self.sessionRunner = sessionRunner
        self.permissionService = permissionService
        super.init()

        configureStatusItem()
        configurePopover()
        bindStatusItemAppearance()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.imagePosition = .imageOnly
        updateStatusItemAppearance()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: 320, height: 430)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(
                presetStore: presetStore,
                sessionRunner: sessionRunner,
                permissionService: permissionService,
                openSettings: { [weak self] in
                    self?.showSettings()
                }
            )
        )
    }

    private func bindStatusItemAppearance() {
        sessionPhaseCancellable = sessionRunner.$sessionPhase
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: sessionRunner.isSessionActive ? "record.circle.fill" : "record.circle",
            accessibilityDescription: "Meeting Mode"
        )
        button.contentTintColor = sessionRunner.isSessionActive ? .systemRed : nil
    }

    private func showSettings() {
        popover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController.showWindow(nil)
        settingsWindowController.window?.makeKeyAndOrderFront(nil)
    }
}

@MainActor
private final class SettingsWindowController: NSWindowController {
    init(permissionService: PermissionService) {
        let hostingController = NSHostingController(
            rootView: SettingsView(permissionService: permissionService)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = hostingController
        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
