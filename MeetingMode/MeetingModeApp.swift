import AppKit
import Combine
import SwiftUI

@main
struct MeetingModeApp: App {
    @NSApplicationDelegateAdaptor(MeetingModeAppDelegate.self) private var appDelegate
    @StateObject private var appLanguageService: AppLanguageService
    @StateObject private var presetStore: PresetStore
    @StateObject private var hotkeyService: HotkeyService
    @StateObject private var permissionService: PermissionService
    @StateObject private var sessionRunner: SessionRunner

    init() {
        let appLanguageService = AppLanguageService()
        let presetStore = PresetStore()
        let hotkeyService = HotkeyService()
        let overlayService = OverlayService(appLanguageService: appLanguageService)
        let appLauncherService = AppLauncherService()
        let appVisibilityService = AppVisibilityService()
        let restoreService = RestoreService(
            overlayService: overlayService,
            appLauncherService: appLauncherService,
            appVisibilityService: appVisibilityService
        )
        let permissionService = PermissionService()
        let sessionRunner = SessionRunner(
            appLauncherService: appLauncherService,
            appVisibilityService: appVisibilityService,
            overlayService: overlayService,
            restoreService: restoreService
        )

        _appLanguageService = StateObject(wrappedValue: appLanguageService)
        _presetStore = StateObject(wrappedValue: presetStore)
        _hotkeyService = StateObject(wrappedValue: hotkeyService)
        _permissionService = StateObject(wrappedValue: permissionService)
        _sessionRunner = StateObject(wrappedValue: sessionRunner)

        MeetingModeAppDelegate.dependencies = .init(
            appLanguageService: appLanguageService,
            presetStore: presetStore,
            hotkeyService: hotkeyService,
            sessionRunner: sessionRunner,
            permissionService: permissionService
        )
    }

    var body: some Scene {
        Settings {
            SettingsView(
                appLanguageService: appLanguageService,
                permissionService: permissionService,
                hotkeyService: hotkeyService
            )
        }
    }
}

@MainActor
final class MeetingModeAppDelegate: NSObject, NSApplicationDelegate {
    struct Dependencies {
        let appLanguageService: AppLanguageService
        let presetStore: PresetStore
        let hotkeyService: HotkeyService
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
            appLanguageService: dependencies.appLanguageService,
            presetStore: dependencies.presetStore,
            hotkeyService: dependencies.hotkeyService,
            sessionRunner: dependencies.sessionRunner,
            permissionService: dependencies.permissionService
        )
    }
}

@MainActor
private final class StatusBarController: NSObject {
    private let appLanguageService: AppLanguageService
    private let presetStore: PresetStore
    private let hotkeyService: HotkeyService
    private let sessionRunner: SessionRunner
    private let permissionService: PermissionService
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private lazy var settingsWindowController = SettingsWindowController(
        appLanguageService: appLanguageService,
        permissionService: permissionService,
        hotkeyService: hotkeyService
    )
    private var presetEditorWindowController: PresetEditorWindowController?
    private var sessionPhaseCancellable: AnyCancellable?
    private var languageCancellable: AnyCancellable?

    init(
        appLanguageService: AppLanguageService,
        presetStore: PresetStore,
        hotkeyService: HotkeyService,
        sessionRunner: SessionRunner,
        permissionService: PermissionService
    ) {
        self.appLanguageService = appLanguageService
        self.presetStore = presetStore
        self.hotkeyService = hotkeyService
        self.sessionRunner = sessionRunner
        self.permissionService = permissionService
        super.init()

        configureStatusItem()
        configurePopover()
        configureHotkeys()
        bindStatusItemAppearance()
        bindLanguageUpdates()
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
                appLanguageService: appLanguageService,
                presetStore: presetStore,
                sessionRunner: sessionRunner,
                permissionService: permissionService,
                startSession: { [weak self] in
                    self?.startSelectedSession()
                },
                openPresetCreator: { [weak self] in
                    self?.presentPresetEditor(mode: .create)
                },
                openPresetEditor: { [weak self] preset in
                    self?.presentPresetEditor(mode: .edit, preset: preset)
                },
                openSettings: { [weak self] in
                    self?.showSettings()
                },
                restoreSession: { [weak self] in
                    self?.restoreSession()
                }
            )
        )
    }

    private func configureHotkeys() {
        hotkeyService.setHandler(for: .startSession) { [weak self] in
            self?.startSelectedSession()
        }
        hotkeyService.setHandler(for: .restoreSession) { [weak self] in
            self?.restoreSession()
        }
    }

    private func bindStatusItemAppearance() {
        sessionPhaseCancellable = sessionRunner.$sessionPhase
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
    }

    private func bindLanguageUpdates() {
        languageCancellable = appLanguageService.$selectedLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.configurePopover()
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

    private func presentPresetEditor(mode: PresetEditorView.Mode, preset: Preset? = nil) {
        popover.performClose(nil)
        presetEditorWindowController?.close()

        let controller = PresetEditorWindowController(
            appLanguageService: appLanguageService,
            mode: mode,
            preset: preset,
            onSave: { [weak self] preset in
                guard let self else {
                    return
                }

                switch mode {
                case .create:
                    self.presetStore.addPreset(preset)
                case .edit:
                    self.presetStore.updatePreset(preset)
                }
            },
            onClose: { [weak self] in
                self?.presetEditorWindowController = nil
            }
        )

        presetEditorWindowController = controller
        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func startSelectedSession() {
        popover.performClose(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else {
                return
            }

            self.sessionRunner.startIfPossible(with: self.presetStore.selectedPreset)
        }
    }

    private func restoreSession() {
        popover.performClose(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.sessionRunner.restoreIfPossible()
        }
    }
}

@MainActor
private final class SettingsWindowController: NSWindowController {
    private let appLanguageService: AppLanguageService
    private let hostingController: NSHostingController<SettingsView>
    private var languageCancellable: AnyCancellable?

    init(
        appLanguageService: AppLanguageService,
        permissionService: PermissionService,
        hotkeyService: HotkeyService
    ) {
        self.appLanguageService = appLanguageService
        let hostingController = NSHostingController(
            rootView: SettingsView(
                appLanguageService: appLanguageService,
                permissionService: permissionService,
                hotkeyService: hotkeyService
            )
        )
        self.hostingController = hostingController
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = appLanguageService.localized(
            "settings.window.title",
            defaultValue: "Settings"
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = hostingController
        super.init(window: window)
        shouldCascadeWindows = false
        languageCancellable = appLanguageService.$selectedLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshLocalization()
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func refreshLocalization() {
        window?.title = appLanguageService.localized(
            "settings.window.title",
            defaultValue: "Settings"
        )
    }
}

@MainActor
private final class PresetEditorWindowController: NSWindowController, NSWindowDelegate {
    private let appLanguageService: AppLanguageService
    private let mode: PresetEditorView.Mode
    private let preset: Preset?
    private let onSave: (Preset) -> Void
    private let onClose: () -> Void
    private let hostingController: NSHostingController<PresetEditorView>
    private var languageCancellable: AnyCancellable?

    init(
        appLanguageService: AppLanguageService,
        mode: PresetEditorView.Mode,
        preset: Preset?,
        onSave: @escaping (Preset) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.appLanguageService = appLanguageService
        self.mode = mode
        self.preset = preset
        self.onSave = onSave
        self.onClose = onClose

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        let hostingController = NSHostingController(
            rootView: PresetEditorView(
                appLanguageService: appLanguageService,
                mode: mode,
                preset: preset,
                onCancel: {
                    window.close()
                },
                onSave: { updatedPreset in
                    onSave(updatedPreset)
                }
            )
        )
        self.hostingController = hostingController

        window.title = mode.title(using: appLanguageService)
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 540, height: 640)
        window.maxSize = NSSize(width: 540, height: 1200)

        super.init(window: window)
        shouldCascadeWindows = false
        self.window?.delegate = self
        languageCancellable = appLanguageService.$selectedLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshLocalization()
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }

    private func refreshLocalization() {
        window?.title = mode.title(using: appLanguageService)
    }
}
