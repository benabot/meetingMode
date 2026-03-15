import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case french = "fr"

    var id: String { rawValue }

    var localeIdentifier: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .french:
            return "Français"
        }
    }

    static func resolvedDefault(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        for identifier in preferredLanguages {
            if identifier.lowercased().hasPrefix("fr") {
                return .french
            }
        }

        return .english
    }
}

enum L10n {
    private static let defaultsKey = "MeetingMode.appLanguage"

    static func currentLanguage(defaults: UserDefaults? = .standard) -> AppLanguage {
        guard
            let rawValue = defaults?.string(forKey: defaultsKey),
            let language = AppLanguage(rawValue: rawValue)
        else {
            return AppLanguage.resolvedDefault()
        }

        return language
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }

    static func string(
        _ key: String,
        language: AppLanguage? = nil,
        defaultValue: String? = nil,
        arguments: [CVarArg] = []
    ) -> String {
        let resolvedLanguage = language ?? currentLanguage()
        let bundle = bundle(for: resolvedLanguage)
        let fallback = defaultValue ?? key
        let format = bundle.localizedString(forKey: key, value: fallback, table: "Localizable")

        guard !arguments.isEmpty else {
            return format
        }

        return String(
            format: format,
            locale: Locale(identifier: resolvedLanguage.localeIdentifier),
            arguments: arguments
        )
    }
}

@MainActor
final class AppLanguageService: ObservableObject {
    private let defaults: UserDefaults?

    @Published private(set) var selectedLanguage: AppLanguage

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        self.selectedLanguage = L10n.currentLanguage(defaults: defaults)
    }

    var locale: Locale {
        Locale(identifier: selectedLanguage.localeIdentifier)
    }

    func updateLanguage(_ language: AppLanguage) {
        guard selectedLanguage != language else {
            return
        }

        selectedLanguage = language
        defaults?.set(language.rawValue, forKey: "MeetingMode.appLanguage")
    }

    func localized(_ key: String, defaultValue: String? = nil) -> String {
        L10n.string(key, language: selectedLanguage, defaultValue: defaultValue)
    }

    func localized(_ key: String, defaultValue: String? = nil, _ arguments: CVarArg...) -> String {
        localized(key, defaultValue: defaultValue, arguments: arguments)
    }

    func localized(_ key: String, defaultValue: String? = nil, arguments: [CVarArg]) -> String {
        L10n.string(
            key,
            language: selectedLanguage,
            defaultValue: defaultValue,
            arguments: arguments
        )
    }
}
