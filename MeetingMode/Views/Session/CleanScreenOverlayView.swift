import SwiftUI

struct CleanScreenOverlayView: View {
    @ObservedObject var appLanguageService: AppLanguageService

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.96),
                    Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.94),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 14) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 34, weight: .semibold))

                Text(
                    appLanguageService.localized(
                        "overlay.title",
                        defaultValue: "Clean screen background enabled"
                    )
                )
                    .font(.title3.weight(.semibold))

                Text(
                    appLanguageService.localized(
                        "overlay.detail",
                        defaultValue: "Use the Meeting Mode menu bar item to restore your session."
                    )
                )
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CleanScreenOverlayView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "OverlayPreviewLanguage"))
    )
        .frame(width: 900, height: 540)
}
