import SwiftUI

struct CleanScreenOverlayView: View {
    @ObservedObject var appLanguageService: AppLanguageService

    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.99),
                Color(red: 0.06, green: 0.07, blue: 0.09).opacity(0.985),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CleanScreenOverlayView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "OverlayPreviewLanguage"))
    )
        .frame(width: 900, height: 540)
}
