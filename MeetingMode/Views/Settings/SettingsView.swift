import Carbon
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appLanguageService: AppLanguageService
    @ObservedObject var launchAtLoginService: LaunchAtLoginService
    @ObservedObject var permissionService: PermissionService
    @ObservedObject var hotkeyService: HotkeyService
    let showTutorial: () -> Void

    @State private var recordingAction: HotkeyAction?
    @State private var hotkeyErrorMessage: String?
    @State private var recordingMonitor: Any?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox(t("settings.group.project_status", "Project Status")) {
                    Text(t("settings.project_status.description", "Technical scaffold only. Launch, clean screen, restore, permissions, and persistence remain intentionally minimal."))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox(t("app.language.section", "Language")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(t("app.language.description", "Choose the app language. The change applies to Meeting Mode windows and popovers."))
                            .foregroundStyle(.secondary)

                        Picker("", selection: languageSelection) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox(t("settings.group.startup", "Startup")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(t("settings.launch_at_login.description", "Use the native macOS login item setting for Meeting Mode."))
                            .foregroundStyle(.secondary)

                        Toggle(
                            t("settings.launch_at_login.title", "Launch at login"),
                            isOn: launchAtLoginBinding
                        )

                        Text(launchAtLoginService.status.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox(t("settings.group.shortcuts", "Shortcuts")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(t("settings.shortcuts.description", "Configure one shortcut for Start Session and one for Restore Session. Shortcuts stay local to this Mac and remain active while Meeting Mode is running."))
                            .foregroundStyle(.secondary)

                        shortcutRow(for: .startSession)
                        shortcutRow(for: .restoreSession)

                        if let hotkeyErrorMessage {
                            Text(hotkeyErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Text(t("settings.shortcuts.recording_hint", "Recording requires at least one modifier key. Press Escape to cancel."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox(t("settings.group.permissions", "Permissions")) {
                    VStack(alignment: .leading, spacing: 12) {
                        permissionRow(
                            title: t("settings.permissions.accessibility", "Accessibility"),
                            status: permissionService.accessibilityStatus,
                            note: t("settings.permissions.accessibility.note", "Not checked in the current scaffold. This only matters once app hiding or restore becomes real.")
                        )
                        permissionRow(
                            title: t("settings.permissions.automation", "Automation"),
                            status: permissionService.automationStatus,
                            note: t("settings.permissions.automation.note", "Not checked in the current scaffold. This only matters once real app control is added.")
                        )
                        permissionRow(
                            title: t("settings.permissions.screen_recording", "Screen Recording"),
                            status: permissionService.screenRecordingStatus,
                            note: t("settings.permissions.screen_recording.note", "Not checked in the current scaffold. The current app does not require it.")
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox(t("settings.group.scope_guardrails", "Scope Guardrails")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("settings.scope.one_session", "One active session at a time."))
                        Text(t("settings.scope.local_persistence", "No persistence layer beyond local files and preferences."))
                        Text(t("settings.scope.no_advanced_automation", "No app automation beyond the current MVP scope."))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox(t("settings.group.help", "Help")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(t("settings.help.description", "Reopen the quick tutorial at any time if you need a short reminder of the main flow and limits."))
                            .foregroundStyle(.secondary)

                        Button(t("settings.help.show_tutorial", "Show Tutorial")) {
                            showTutorial()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 520, minHeight: 560)
        .onAppear {
            launchAtLoginService.refreshStatus()
        }
        .onChange(of: recordingAction) { _, newValue in
            if newValue == nil {
                hotkeyService.resumeRegistrations()
                removeRecordingMonitor()
            } else {
                hotkeyErrorMessage = nil
                hotkeyService.suspendRegistrations()
                installRecordingMonitor()
            }
        }
        .onDisappear {
            recordingAction = nil
            removeRecordingMonitor()
            hotkeyService.resumeRegistrations()
        }
        .onChange(of: appLanguageService.selectedLanguage) { _, _ in
            hotkeyErrorMessage = nil
        }
    }

    private func shortcutRow(for action: HotkeyAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.headline)

                    Text(hotkeyService.shortcut(for: action)?.displayString ?? t("settings.shortcuts.not_set", "Not set"))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(recordingButtonTitle(for: action)) {
                    toggleRecording(for: action)
                }
                .buttonStyle(.borderedProminent)

                Button(t("settings.shortcuts.clear", "Clear")) {
                    clearShortcut(for: action)
                }
                .disabled(hotkeyService.shortcut(for: action) == nil)
            }

            if recordingAction == action {
                Text(t("settings.shortcuts.recording_for_action", "Press the shortcut you want to use for %@.", action.title))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func recordingButtonTitle(for action: HotkeyAction) -> String {
        if recordingAction == action {
            return t("settings.shortcuts.recording", "Press shortcut…")
        }

        return hotkeyService.shortcut(for: action) == nil
            ? t("settings.shortcuts.set", "Set Shortcut")
            : t("settings.shortcuts.change", "Change")
    }

    private func toggleRecording(for action: HotkeyAction) {
        hotkeyErrorMessage = nil
        recordingAction = recordingAction == action ? nil : action
    }

    private func clearShortcut(for action: HotkeyAction) {
        hotkeyErrorMessage = nil
        recordingAction = nil
        hotkeyService.clearShortcut(for: action)
    }

    private func installRecordingMonitor() {
        guard recordingMonitor == nil else {
            return
        }

        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let recordingAction else {
                return event
            }

            if event.keyCode == UInt16(kVK_Escape) {
                self.recordingAction = nil
                return nil
            }

            guard let shortcut = HotkeyShortcut.from(event: event) else {
                self.hotkeyErrorMessage = HotkeyConfigurationError.missingModifier.errorDescription
                return nil
            }

            do {
                try hotkeyService.updateShortcut(shortcut, for: recordingAction)
                self.hotkeyErrorMessage = nil
                self.recordingAction = nil
            } catch {
                self.hotkeyErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }

            return nil
        }
    }

    private func removeRecordingMonitor() {
        guard let recordingMonitor else {
            return
        }

        NSEvent.removeMonitor(recordingMonitor)
        self.recordingMonitor = nil
    }

    private func permissionRow(title: String, status: PermissionStatus, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text(status.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(note)
                .foregroundStyle(.secondary)

            Text(status.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { appLanguageService.selectedLanguage },
            set: { appLanguageService.updateLanguage($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginService.status.isEnabled },
            set: { launchAtLoginService.setEnabled($0) }
        )
    }

    private func t(_ key: String, _ defaultValue: String, _ arguments: CVarArg...) -> String {
        appLanguageService.localized(key, defaultValue: defaultValue, arguments)
    }
}

#Preview {
    SettingsView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "SettingsViewPreviewLanguage")),
        launchAtLoginService: LaunchAtLoginService(),
        permissionService: PermissionService(),
        hotkeyService: HotkeyService(defaults: UserDefaults(suiteName: "SettingsViewPreview")),
        showTutorial: {}
    )
}
