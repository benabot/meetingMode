import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PresetEditorView: View {
    private static let contentWidth: CGFloat = 500

    enum Mode {
        case create
        case edit

        func title(using appLanguageService: AppLanguageService) -> String {
            switch self {
            case .create:
                return appLanguageService.localized(
                    "preset_editor.mode.create.title",
                    defaultValue: "New Preset"
                )
            case .edit:
                return appLanguageService.localized(
                    "preset_editor.mode.edit.title",
                    defaultValue: "Edit Preset"
                )
            }
        }

        func saveButtonTitle(using appLanguageService: AppLanguageService) -> String {
            switch self {
            case .create:
                return appLanguageService.localized(
                    "preset_editor.mode.create.save",
                    defaultValue: "Create Preset"
                )
            case .edit:
                return appLanguageService.localized(
                    "preset_editor.mode.edit.save",
                    defaultValue: "Save Changes"
                )
            }
        }
    }

    @ObservedObject var appLanguageService: AppLanguageService
    @State private var draft: PresetEditorDraft

    let mode: Mode
    let onCancel: () -> Void
    let onSave: (Preset) -> Void

    init(
        appLanguageService: AppLanguageService,
        mode: Mode,
        preset: Preset? = nil,
        onCancel: @escaping () -> Void = {},
        onSave: @escaping (Preset) -> Void
    ) {
        self.appLanguageService = appLanguageService
        self.mode = mode
        self.onCancel = onCancel
        self.onSave = onSave
        _draft = State(initialValue: PresetEditorDraft(preset: preset))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    editorSection(title: t("preset_editor.section.basics", "Basics")) {
                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel(t("preset_editor.field.name", "Preset name"))
                            TextField(t("preset_editor.placeholder.name", "Weekly client sync"), text: $draft.name)
                                .textFieldStyle(.roundedBorder)

                            fieldLabel(t("preset_editor.field.icon", "Icon"))
                            TextField(t("preset_editor.placeholder.icon", "sparkles"), text: $draft.iconSystemName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    editorSection(title: t("preset_editor.section.what_starts", "What starts")) {
                        VStack(alignment: .leading, spacing: 14) {
                            selectedAppsBlock

                            textEditorBlock(
                                title: t("preset_editor.field.open_links", "Open links"),
                                text: $draft.urlsText,
                                placeholder: t("preset_editor.placeholder.links", "https://meet.example.com/demo\nhttps://docs.example.com/brief"),
                                height: 88,
                                usesMonospacedText: true
                            )

                            textEditorBlock(
                                title: t("preset_editor.field.open_files", "Open files"),
                                text: $draft.filesText,
                                placeholder: t("preset_editor.placeholder.files", "/Users/benoitabot/Documents/brief.pdf\n/Users/benoitabot/Desktop/demo.key"),
                                height: 88,
                                usesMonospacedText: true
                            )

                            Toggle(t("preset_editor.toggle.clean_screen", "Show clean screen"), isOn: $draft.showsOverlay)
                        }
                    }

                    editorSection(title: t("preset_editor.section.checklist", "Checklist")) {
                        textEditorBlock(
                            title: t("preset_editor.field.checklist", "Checklist"),
                            text: $draft.checklistText,
                            placeholder: t("preset_editor.placeholder.checklist", "Check microphone\nClose private tabs\nShare the right screen"),
                            height: 110,
                            usesMonospacedText: false
                        )
                    }
                }
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            footer
        }
        .padding(20)
        .frame(width: Self.contentWidth, alignment: .leading)
        .frame(minHeight: 620)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mode.title(using: appLanguageService))
                .font(.title3.weight(.semibold))

            Text(t("preset_editor.validation.header", "A preset needs at least one app, link, file, or clean screen to start."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(validationMessage)
                .font(.caption)
                .foregroundStyle(draft.hasStartableActions ? Color.secondary : Color.orange)
        }
    }

    private var selectedAppsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                fieldLabel(t("preset_editor.field.open_apps", "Open apps"))

                Spacer(minLength: 12)

                Button(t("preset_editor.button.add_app", "Add App…")) {
                    presentAppPicker()
                }
                .controlSize(.small)
            }

            if draft.apps.isEmpty {
                Text(t("preset_editor.apps.none", "No apps selected yet."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(sectionBackground)
            } else {
                VStack(spacing: 8) {
                    ForEach(draft.apps) { app in
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.normalizedDisplayName.isEmpty ? t("preset_editor.apps.selected_fallback", "Selected App") : app.normalizedDisplayName)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let secondaryLabel = app.secondaryLabel {
                                    Text(secondaryLabel)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .layoutPriority(1)

                            Spacer(minLength: 8)

                            Button {
                                draft.removeApp(app)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 18, alignment: .center)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(sectionBackground)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(alignment: .center) {
            if !draft.canSave {
                Text(footerMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(t("preset_editor.button.cancel", "Cancel")) {
                onCancel()
            }

            Button(mode.saveButtonTitle(using: appLanguageService)) {
                onSave(draft.makePreset())
                onCancel()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!draft.canSave)
        }
    }

    private func editorSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionBackground)
    }

    private func textEditorBlock(
        title: String,
        text: Binding<String>,
        placeholder: String,
        height: CGFloat,
        usesMonospacedText: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)

            PlaceholderTextEditor(
                text: text,
                placeholder: placeholder,
                height: height,
                usesMonospacedText: usesMonospacedText
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.medium))
    }

    private func presentAppPicker() {
        let panel = NSOpenPanel()
        panel.title = t("preset_editor.app_picker.title", "Add Apps")
        panel.prompt = t("preset_editor.app_picker.prompt", "Add App")
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.treatsFilePackagesAsDirectories = false

        if panel.runModal() == .OK {
            draft.addApplications(from: panel.urls)
        }
    }

    private var sectionBackground: some ShapeStyle {
        Color(NSColor.controlBackgroundColor)
    }

    private var validationMessage: String {
        if draft.trimmedName.isEmpty {
            return t(
                "preset_editor.validation.missing_name",
                "Add a preset name, then add at least one app, link, file, or clean screen."
            )
        }

        if draft.hasStartableActions {
            return t(
                "preset_editor.validation.startable",
                "This preset is startable."
            )
        }

        return t(
            "preset_editor.validation.missing_action",
            "Add at least one app, link, file, or enable clean screen."
        )
    }

    private var footerMessage: String {
        if draft.trimmedName.isEmpty {
            return t(
                "preset_editor.validation.footer_name",
                "Enter a preset name to continue."
            )
        }

        return t(
            "preset_editor.validation.footer_action",
            "Add at least one app, link, file, or enable clean screen."
        )
    }

    private func t(_ key: String, _ defaultValue: String, _ arguments: CVarArg...) -> String {
        appLanguageService.localized(key, defaultValue: defaultValue, arguments: arguments)
    }
}

#Preview("Create Preset") {
    PresetEditorView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "PresetEditorPreviewLanguage")),
        mode: .create
    ) { _ in }
}

#Preview("Edit Preset") {
    PresetEditorView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "PresetEditorPreviewLanguage2")),
        mode: .edit,
        preset: Preset(
            name: "Client Call",
            iconSystemName: "person.2.fill",
            appsToLaunch: [
                PresetApp(displayName: "Calendar", bundleIdentifier: "com.apple.iCal", bundlePath: "/System/Applications/Calendar.app"),
                PresetApp(displayName: "Notes", bundleIdentifier: "com.apple.Notes", bundlePath: "/System/Applications/Notes.app"),
                PresetApp(displayName: "Safari", bundleIdentifier: "com.apple.Safari", bundlePath: "/Applications/Safari.app"),
            ],
            urlsToOpen: ["https://meet.example.com/client-call"],
            filesToOpen: ["/Users/benoitabot/Documents/Client Brief.pdf"],
            checklistItems: [
                ChecklistItem(title: "Open call brief"),
                ChecklistItem(title: "Check microphone"),
            ],
            showsOverlay: true
        )
    ) { _ in }
}

private struct PresetEditorDraft {
    var id: UUID?
    var name: String
    var iconSystemName: String
    var apps: [PresetApp]
    var urlsText: String
    var filesText: String
    var checklistText: String
    var showsOverlay: Bool

    init(preset: Preset? = nil) {
        id = preset?.id
        name = preset?.name ?? ""
        iconSystemName = preset?.iconSystemName ?? "sparkles"
        apps = preset?.appsToLaunch ?? []
        urlsText = preset?.urlsToOpen.joined(separator: "\n") ?? ""
        filesText = preset?.filesToOpen.joined(separator: "\n") ?? ""
        checklistText = preset?.checklistItems.map(\.title).joined(separator: "\n") ?? ""
        showsOverlay = preset?.showsOverlay ?? false
    }

    var canSave: Bool {
        !trimmedName.isEmpty && hasStartableActions
    }

    var hasStartableActions: Bool {
        !apps.isEmpty
            || !normalizedLines(from: urlsText).isEmpty
            || !normalizedLines(from: filesText).isEmpty
            || showsOverlay
    }

    mutating func addApplications(from urls: [URL]) {
        for url in urls {
            let app = makePresetApp(from: url)
            guard app.hasLaunchTarget else {
                continue
            }

            if apps.contains(where: { $0.deduplicationKey == app.deduplicationKey }) {
                continue
            }

            apps.append(app)
        }

        apps.sort {
            $0.normalizedDisplayName.localizedCaseInsensitiveCompare($1.normalizedDisplayName) == .orderedAscending
        }
    }

    mutating func removeApp(_ app: PresetApp) {
        apps.removeAll { $0.id == app.id }
    }

    func makePreset() -> Preset {
        Preset(
            id: id ?? UUID(),
            name: trimmedName,
            iconSystemName: normalizedIconSystemName,
            appsToLaunch: apps,
            urlsToOpen: normalizedLines(from: urlsText),
            filesToOpen: normalizedLines(from: filesText),
            checklistItems: normalizedLines(from: checklistText).map { ChecklistItem(title: $0) },
            showsOverlay: showsOverlay
        )
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedIconSystemName: String {
        let trimmed = iconSystemName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "sparkles" : trimmed
    }

    private func normalizedLines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func makePresetApp(from url: URL) -> PresetApp {
        let bundle = Bundle(url: url)
        let displayName = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent

        return PresetApp(
            displayName: displayName,
            bundleIdentifier: bundle?.bundleIdentifier,
            bundlePath: url.path
        )
    }
}

private struct PlaceholderTextEditor: View {
    @Binding var text: String

    let placeholder: String
    let height: CGFloat
    let usesMonospacedText: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(editorFont)
                .scrollContentBackground(.hidden)
                .padding(4)
                .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor))
                )

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(editorFont)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var editorFont: Font {
        usesMonospacedText ? .body.monospaced() : .body
    }
}
