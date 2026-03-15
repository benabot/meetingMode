import Carbon
import SwiftUI

struct SettingsView: View {
    @ObservedObject var permissionService: PermissionService
    @ObservedObject var hotkeyService: HotkeyService

    @State private var recordingAction: HotkeyAction?
    @State private var hotkeyErrorMessage: String?
    @State private var recordingMonitor: Any?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Project Status") {
                    Text("Technical scaffold only. Launch, clean screen, restore, permissions, and persistence remain intentionally minimal.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Shortcuts") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Configure one shortcut for Start Session and one for Restore Session. Shortcuts stay local to this Mac and remain active while Meeting Mode is running.")
                            .foregroundStyle(.secondary)

                        shortcutRow(for: .startSession)
                        shortcutRow(for: .restoreSession)

                        if let hotkeyErrorMessage {
                            Text(hotkeyErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Text("Recording requires at least one modifier key. Press Escape to cancel.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Permissions") {
                    VStack(alignment: .leading, spacing: 12) {
                        permissionRow(
                            title: "Accessibility",
                            status: permissionService.accessibilityStatus,
                            note: "Not checked in the current scaffold. This only matters once app hiding or restore becomes real."
                        )
                        permissionRow(
                            title: "Automation",
                            status: permissionService.automationStatus,
                            note: "Not checked in the current scaffold. This only matters once real app control is added."
                        )
                        permissionRow(
                            title: "Screen Recording",
                            status: permissionService.screenRecordingStatus,
                            note: "Not checked in the current scaffold. The current app does not require it."
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Scope Guardrails") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("One active session at a time.")
                        Text("No persistence layer beyond local files and preferences.")
                        Text("No app automation beyond the current MVP scope.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 520, minHeight: 420)
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
    }

    private func shortcutRow(for action: HotkeyAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.headline)

                    Text(hotkeyService.shortcut(for: action)?.displayString ?? "Not set")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(recordingButtonTitle(for: action)) {
                    toggleRecording(for: action)
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    clearShortcut(for: action)
                }
                .disabled(hotkeyService.shortcut(for: action) == nil)
            }

            if recordingAction == action {
                Text("Press the shortcut you want to use for \(action.title).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func recordingButtonTitle(for action: HotkeyAction) -> String {
        if recordingAction == action {
            return "Press shortcut…"
        }

        return hotkeyService.shortcut(for: action) == nil ? "Set Shortcut" : "Change"
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

                Text(status.rawValue)
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
}

#Preview {
    SettingsView(
        permissionService: PermissionService(),
        hotkeyService: HotkeyService(defaults: UserDefaults(suiteName: "SettingsViewPreview"))
    )
}
