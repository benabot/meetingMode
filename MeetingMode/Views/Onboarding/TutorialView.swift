import SwiftUI

struct TutorialView: View {
    struct Page: Identifiable {
        let id: Int
        let iconSystemName: String
        let titleKey: String
        let titleDefault: String
        let bodyKey: String
        let bodyDefault: String
        let bulletKeys: [(String, String)]
    }

    @ObservedObject var appLanguageService: AppLanguageService
    @State private var pageIndex = 0

    let onSkip: () -> Void
    let onDone: () -> Void

    private var pages: [Page] {
        [
            Page(
                id: 0,
                iconSystemName: "menubar.rectangle",
                titleKey: "tutorial.page1.title",
                titleDefault: "What Meeting Mode does",
                bodyKey: "tutorial.page1.body",
                bodyDefault: "Meeting Mode prepares this Mac for a meeting, a demo, or a screen share from the menu bar.",
                bulletKeys: [
                    ("tutorial.page1.bullet1", "Run a preset in one click."),
                    ("tutorial.page1.bullet2", "Keep the setup small and predictable."),
                ]
            ),
            Page(
                id: 1,
                iconSystemName: "tray.full",
                titleKey: "tutorial.page2.title",
                titleDefault: "What a preset is",
                bodyKey: "tutorial.page2.body",
                bodyDefault: "A preset describes what should be ready before you start sharing.",
                bulletKeys: [
                    ("tutorial.page2.bullet1", "Apps to open."),
                    ("tutorial.page2.bullet2", "Links and local files to open."),
                    ("tutorial.page2.bullet3", "Checklist items and an optional clean screen."),
                ]
            ),
            Page(
                id: 2,
                iconSystemName: "play.circle",
                titleKey: "tutorial.page3.title",
                titleDefault: "What Start Session does",
                bodyKey: "tutorial.page3.body",
                bodyDefault: "Start Session applies the preset with the current MVP rules.",
                bulletKeys: [
                    ("tutorial.page3.bullet1", "Opens the preset apps, links, and files."),
                    ("tutorial.page3.bullet2", "May hide visible apps outside the preset in best effort."),
                    ("tutorial.page3.bullet3", "Can show a clean screen background."),
                ]
            ),
            Page(
                id: 3,
                iconSystemName: "arrow.uturn.backward.circle",
                titleKey: "tutorial.page4.title",
                titleDefault: "What Restore Session does",
                bodyKey: "tutorial.page4.body",
                bodyDefault: "Restore Session only targets the changes that Meeting Mode actually made.",
                bulletKeys: [
                    ("tutorial.page4.bullet1", "Hides the clean screen."),
                    ("tutorial.page4.bullet2", "Tries to re-show apps that Meeting Mode itself hid."),
                    ("tutorial.page4.bullet3", "Stays best effort only."),
                ]
            ),
            Page(
                id: 4,
                iconSystemName: "exclamationmark.triangle",
                titleKey: "tutorial.page5.title",
                titleDefault: "Important limits",
                bodyKey: "tutorial.page5.body",
                bodyDefault: "This MVP keeps the scope intentionally narrow.",
                bulletKeys: [
                    ("tutorial.page5.bullet1", "No perfect restore of windows, tabs, or Spaces."),
                    ("tutorial.page5.bullet2", "No advanced window management in v1."),
                    ("tutorial.page5.bullet3", "Some behavior still depends on what macOS allows."),
                ]
            ),
        ]
    }

    var body: some View {
        let page = pages[pageIndex]

        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(t("tutorial.title", "Quick Tutorial"))
                    .font(.title3.weight(.semibold))

                Spacer()

                Text(t("tutorial.progress", "%d of %d", pageIndex + 1, pages.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: page.iconSystemName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text(t(page.titleKey, page.titleDefault))
                    .font(.title2.weight(.semibold))

                Text(t(page.bodyKey, page.bodyDefault))
                    .font(.body)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(page.bulletKeys.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(t(page.bulletKeys[index].0, page.bulletKeys[index].1))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            HStack {
                Button(t("tutorial.skip", "Skip")) {
                    onSkip()
                }

                Spacer()

                if pageIndex > 0 {
                    Button(t("tutorial.back", "Back")) {
                        pageIndex -= 1
                    }
                }

                Button(isLastPage ? t("tutorial.done", "Done") : t("tutorial.next", "Next")) {
                    if isLastPage {
                        onDone()
                    } else {
                        pageIndex += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520, height: 420, alignment: .topLeading)
    }

    private var isLastPage: Bool {
        pageIndex == pages.count - 1
    }

    private func t(_ key: String, _ defaultValue: String, _ arguments: CVarArg...) -> String {
        appLanguageService.localized(key, defaultValue: defaultValue, arguments: arguments)
    }
}

#Preview {
    TutorialView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "TutorialPreviewLanguage")),
        onSkip: {},
        onDone: {}
    )
}
