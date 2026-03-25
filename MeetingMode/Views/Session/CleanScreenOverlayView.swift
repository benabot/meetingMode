import AppKit
import SwiftUI

struct CleanScreenOverlayView: View {
    @ObservedObject var appLanguageService: AppLanguageService
    let background: PresentationBackground

    var body: some View {
        Group {
            switch background.mode {
            case .none:
                Color.clear
            case .solidColor:
                Color(
                    red: background.solidColor.red,
                    green: background.solidColor.green,
                    blue: background.solidColor.blue
                )
                .opacity(background.normalizedOpacity)
            case .image:
                if let image = NSImage(contentsOfFile: background.normalizedImagePath) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(
                        red: background.solidColor.red,
                        green: background.solidColor.green,
                        blue: background.solidColor.blue
                    )
                    .opacity(background.normalizedOpacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

#if DEBUG
#Preview {
    CleanScreenOverlayView(
        appLanguageService: AppLanguageService(defaults: UserDefaults(suiteName: "OverlayPreviewLanguage")),
        background: .solidColor()
    )
        .frame(width: 900, height: 540)
}
#endif
