import AppKit
import Carbon
import Combine
import Foundation

enum HotkeyAction: String, CaseIterable, Identifiable {
    case startSession
    case restoreSession

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startSession:
            return L10n.string(
                "hotkeys.action.start",
                defaultValue: "Start Session"
            )
        case .restoreSession:
            return L10n.string(
                "hotkeys.action.restore",
                defaultValue: "Restore Session"
            )
        }
    }

    fileprivate var defaultsKey: String {
        switch self {
        case .startSession:
            return "MeetingMode.hotkey.startSession"
        case .restoreSession:
            return "MeetingMode.hotkey.restoreSession"
        }
    }

    fileprivate var carbonID: UInt32 {
        switch self {
        case .startSession:
            return 1
        case .restoreSession:
            return 2
        }
    }

    fileprivate init?(carbonID: UInt32) {
        switch carbonID {
        case 1:
            self = .startSession
        case 2:
            self = .restoreSession
        default:
            return nil
        }
    }
}

struct HotkeyShortcut: Codable, Hashable {
    let keyCode: UInt16
    let modifierFlagsRawValue: UInt

    init(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifierFlagsRawValue = Self.sanitizedModifierFlags(modifierFlags).rawValue
    }

    var modifierFlags: NSEvent.ModifierFlags {
        Self.sanitizedModifierFlags(NSEvent.ModifierFlags(rawValue: modifierFlagsRawValue))
    }

    var isValid: Bool {
        !modifierFlags.isEmpty
    }

    var displayString: String {
        let modifierDisplay = [
            modifierFlags.contains(.control) ? "⌃" : nil,
            modifierFlags.contains(.option) ? "⌥" : nil,
            modifierFlags.contains(.shift) ? "⇧" : nil,
            modifierFlags.contains(.command) ? "⌘" : nil,
        ]
        .compactMap { $0 }
        .joined()

        return modifierDisplay + Self.keyDisplayName(for: keyCode)
    }

    fileprivate var carbonModifierFlags: UInt32 {
        var modifiers: UInt32 = 0

        if modifierFlags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if modifierFlags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if modifierFlags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if modifierFlags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }

        return modifiers
    }

    static func from(event: NSEvent) -> HotkeyShortcut? {
        let shortcut = HotkeyShortcut(
            keyCode: event.keyCode,
            modifierFlags: event.modifierFlags
        )

        return shortcut.isValid ? shortcut : nil
    }

    private static func sanitizedModifierFlags(_ flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection([.command, .option, .control, .shift])
    }

    private static func keyDisplayName(for keyCode: UInt16) -> String {
        if keyCode == UInt16(kVK_Space) {
            return L10n.string(
                "hotkeys.key.space",
                defaultValue: "Space"
            )
        }

        if let specialKey = specialKeyNames[keyCode] {
            return specialKey
        }

        if let letter = letterKeyNames[keyCode] {
            return letter
        }

        if let digit = digitKeyNames[keyCode] {
            return digit
        }

        if let punctuation = punctuationKeyNames[keyCode] {
            return punctuation
        }

        return L10n.string(
            "hotkeys.key.unknown",
            defaultValue: "Key %d",
            arguments: [Int(keyCode)]
        )
    }

    private static let letterKeyNames: [UInt16: String] = [
        UInt16(kVK_ANSI_A): "A",
        UInt16(kVK_ANSI_B): "B",
        UInt16(kVK_ANSI_C): "C",
        UInt16(kVK_ANSI_D): "D",
        UInt16(kVK_ANSI_E): "E",
        UInt16(kVK_ANSI_F): "F",
        UInt16(kVK_ANSI_G): "G",
        UInt16(kVK_ANSI_H): "H",
        UInt16(kVK_ANSI_I): "I",
        UInt16(kVK_ANSI_J): "J",
        UInt16(kVK_ANSI_K): "K",
        UInt16(kVK_ANSI_L): "L",
        UInt16(kVK_ANSI_M): "M",
        UInt16(kVK_ANSI_N): "N",
        UInt16(kVK_ANSI_O): "O",
        UInt16(kVK_ANSI_P): "P",
        UInt16(kVK_ANSI_Q): "Q",
        UInt16(kVK_ANSI_R): "R",
        UInt16(kVK_ANSI_S): "S",
        UInt16(kVK_ANSI_T): "T",
        UInt16(kVK_ANSI_U): "U",
        UInt16(kVK_ANSI_V): "V",
        UInt16(kVK_ANSI_W): "W",
        UInt16(kVK_ANSI_X): "X",
        UInt16(kVK_ANSI_Y): "Y",
        UInt16(kVK_ANSI_Z): "Z",
    ]

    private static let digitKeyNames: [UInt16: String] = [
        UInt16(kVK_ANSI_0): "0",
        UInt16(kVK_ANSI_1): "1",
        UInt16(kVK_ANSI_2): "2",
        UInt16(kVK_ANSI_3): "3",
        UInt16(kVK_ANSI_4): "4",
        UInt16(kVK_ANSI_5): "5",
        UInt16(kVK_ANSI_6): "6",
        UInt16(kVK_ANSI_7): "7",
        UInt16(kVK_ANSI_8): "8",
        UInt16(kVK_ANSI_9): "9",
    ]

    private static let punctuationKeyNames: [UInt16: String] = [
        UInt16(kVK_ANSI_Minus): "-",
        UInt16(kVK_ANSI_Equal): "=",
        UInt16(kVK_ANSI_LeftBracket): "[",
        UInt16(kVK_ANSI_RightBracket): "]",
        UInt16(kVK_ANSI_Semicolon): ";",
        UInt16(kVK_ANSI_Quote): "'",
        UInt16(kVK_ANSI_Comma): ",",
        UInt16(kVK_ANSI_Period): ".",
        UInt16(kVK_ANSI_Slash): "/",
        UInt16(kVK_ANSI_Backslash): "\\",
        UInt16(kVK_ANSI_Grave): "`",
    ]

    private static let specialKeyNames: [UInt16: String] = [
        UInt16(kVK_Return): "↩",
        UInt16(kVK_Tab): "⇥",
        UInt16(kVK_Delete): "⌫",
        UInt16(kVK_Escape): "⎋",
        UInt16(kVK_ForwardDelete): "⌦",
        UInt16(kVK_LeftArrow): "←",
        UInt16(kVK_RightArrow): "→",
        UInt16(kVK_UpArrow): "↑",
        UInt16(kVK_DownArrow): "↓",
        UInt16(kVK_F1): "F1",
        UInt16(kVK_F2): "F2",
        UInt16(kVK_F3): "F3",
        UInt16(kVK_F4): "F4",
        UInt16(kVK_F5): "F5",
        UInt16(kVK_F6): "F6",
        UInt16(kVK_F7): "F7",
        UInt16(kVK_F8): "F8",
        UInt16(kVK_F9): "F9",
        UInt16(kVK_F10): "F10",
        UInt16(kVK_F11): "F11",
        UInt16(kVK_F12): "F12",
    ]
}

enum HotkeyConfigurationError: LocalizedError {
    case missingModifier
    case duplicateShortcut
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .missingModifier:
            return L10n.string(
                "hotkeys.error.missing_modifier",
                defaultValue: "Shortcuts must include at least one modifier key."
            )
        case .duplicateShortcut:
            return L10n.string(
                "hotkeys.error.duplicate",
                defaultValue: "Start Session and Restore Session cannot use the same shortcut."
            )
        case .registrationFailed:
            return L10n.string(
                "hotkeys.error.registration_failed",
                defaultValue: "This shortcut could not be registered on this Mac."
            )
        }
    }
}

@MainActor
final class HotkeyService: ObservableObject {
    @Published private(set) var startShortcut: HotkeyShortcut?
    @Published private(set) var restoreShortcut: HotkeyShortcut?

    private let defaults: UserDefaults?
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRefs: [HotkeyAction: EventHotKeyRef?] = [:]
    private var handlers: [HotkeyAction: @MainActor () -> Void] = [:]
    private var isSuspended = false

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        self.startShortcut = Self.loadShortcut(from: defaults, key: HotkeyAction.startSession.defaultsKey)
        self.restoreShortcut = Self.loadShortcut(from: defaults, key: HotkeyAction.restoreSession.defaultsKey)
        installEventHandlerIfNeeded()
        registerAllHotkeys()
    }

    func shortcut(for action: HotkeyAction) -> HotkeyShortcut? {
        switch action {
        case .startSession:
            return startShortcut
        case .restoreSession:
            return restoreShortcut
        }
    }

    func setHandler(for action: HotkeyAction, handler: @escaping @MainActor () -> Void) {
        handlers[action] = handler
    }

    func clearShortcut(for action: HotkeyAction) {
        try? updateShortcut(nil, for: action)
    }

    func updateShortcut(
        _ shortcut: HotkeyShortcut?,
        for action: HotkeyAction
    ) throws {
        if let shortcut, !shortcut.isValid {
            throw HotkeyConfigurationError.missingModifier
        }

        if let shortcut,
           otherAction(for: action).flatMap(shortcut(for:)) == shortcut {
            throw HotkeyConfigurationError.duplicateShortcut
        }

        let previousShortcut = self.shortcut(for: action)
        unregisterHotkey(for: action)

        do {
            if !isSuspended,
               let shortcut {
                try registerHotkey(shortcut, for: action)
            }

            setStoredShortcut(shortcut, for: action)
            persistShortcut(shortcut, for: action)
        } catch {
            if !isSuspended,
               let previousShortcut {
                try? registerHotkey(previousShortcut, for: action)
            }

            throw error
        }
    }

    func suspendRegistrations() {
        guard !isSuspended else {
            return
        }

        isSuspended = true
        unregisterAllHotkeys()
    }

    func resumeRegistrations() {
        guard isSuspended else {
            return
        }

        isSuspended = false
        registerAllHotkeys()
    }

    fileprivate func handleHotkeyEvent(_ action: HotkeyAction) {
        handlers[action]?()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            meetingModeHotkeyHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )
    }

    private func registerAllHotkeys() {
        HotkeyAction.allCases.forEach { action in
            guard let shortcut = shortcut(for: action) else {
                return
            }

            try? registerHotkey(shortcut, for: action)
        }
    }

    private func unregisterAllHotkeys() {
        HotkeyAction.allCases.forEach(unregisterHotkey(for:))
    }

    private func registerHotkey(
        _ shortcut: HotkeyShortcut,
        for action: HotkeyAction
    ) throws {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(
            signature: meetingModeHotkeySignature,
            id: action.carbonID
        )

        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.carbonModifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            throw HotkeyConfigurationError.registrationFailed
        }

        hotKeyRefs[action] = hotKeyRef
    }

    private func unregisterHotkey(for action: HotkeyAction) {
        guard let hotKeyRef = hotKeyRefs[action] ?? nil else {
            hotKeyRefs[action] = nil
            return
        }

        UnregisterEventHotKey(hotKeyRef)
        hotKeyRefs[action] = nil
    }

    private func setStoredShortcut(
        _ shortcut: HotkeyShortcut?,
        for action: HotkeyAction
    ) {
        switch action {
        case .startSession:
            startShortcut = shortcut
        case .restoreSession:
            restoreShortcut = shortcut
        }
    }

    private func persistShortcut(
        _ shortcut: HotkeyShortcut?,
        for action: HotkeyAction
    ) {
        guard let defaults else {
            return
        }

        if let shortcut,
           let data = try? JSONEncoder().encode(shortcut) {
            defaults.set(data, forKey: action.defaultsKey)
        } else {
            defaults.removeObject(forKey: action.defaultsKey)
        }
    }

    private func otherAction(for action: HotkeyAction) -> HotkeyAction? {
        switch action {
        case .startSession:
            return .restoreSession
        case .restoreSession:
            return .startSession
        }
    }

    private static func loadShortcut(
        from defaults: UserDefaults?,
        key: String
    ) -> HotkeyShortcut? {
        guard let data = defaults?.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(HotkeyShortcut.self, from: data)
    }
}

private let meetingModeHotkeySignature: OSType = fourCharCode("MMHK")

private let meetingModeHotkeyHandler: EventHandlerUPP = { _, eventRef, userData in
    guard let eventRef,
          let userData else {
        return noErr
    }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        eventRef,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr,
          let action = HotkeyAction(carbonID: hotKeyID.id) else {
        return noErr
    }

    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()

    Task { @MainActor in
        service.handleHotkeyEvent(action)
    }

    return noErr
}

private func fourCharCode(_ value: String) -> OSType {
    value.utf8.reduce(0) { partialResult, character in
        (partialResult << 8) + OSType(character)
    }
}
