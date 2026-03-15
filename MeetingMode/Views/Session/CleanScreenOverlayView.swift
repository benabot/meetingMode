import SwiftUI

struct CleanScreenOverlayView: View {
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

                Text("Clean screen background enabled")
                    .font(.title3.weight(.semibold))

                Text("Use the Meeting Mode menu bar item to restore your session.")
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
    CleanScreenOverlayView()
        .frame(width: 900, height: 540)
}
