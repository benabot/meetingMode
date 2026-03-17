import AppKit
import SwiftUI

enum MeetingModeVisualTone {
    case neutral
    case accent
    case positive
    case critical

    var tint: Color {
        switch self {
        case .neutral:
            return Color(red: 0.31, green: 0.39, blue: 0.49)
        case .accent:
            return Color(red: 0.16, green: 0.50, blue: 0.98)
        case .positive:
            return Color(red: 0.16, green: 0.68, blue: 0.42)
        case .critical:
            return Color(red: 0.92, green: 0.28, blue: 0.26)
        }
    }

    var emphasis: Color {
        switch self {
        case .neutral:
            return Color(red: 0.18, green: 0.22, blue: 0.29)
        case .accent:
            return Color(red: 0.06, green: 0.34, blue: 0.82)
        case .positive:
            return Color(red: 0.08, green: 0.53, blue: 0.31)
        case .critical:
            return Color(red: 0.77, green: 0.19, blue: 0.18)
        }
    }
}

enum MeetingModeGlassCardStyle {
    case hero
    case section
    case action
    case footer
}

enum MeetingModeButtonRole {
    case primary
    case secondary
    case destructive
}

enum MeetingModeButtonSize {
    case regular
    case compact
}

enum MeetingModeTextPalette {
    static let primary = Color(red: 0.14, green: 0.17, blue: 0.22)
    static let secondary = Color(red: 0.31, green: 0.35, blue: 0.43)
    static let muted = Color(red: 0.43, green: 0.47, blue: 0.56)
    static let disabled = Color(red: 0.56, green: 0.60, blue: 0.68)
}

struct MeetingModeWindowBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.95, blue: 0.985),
                    Color(red: 0.84, green: 0.89, blue: 0.96),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.34),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 220
            )

            RadialGradient(
                colors: [
                    MeetingModeVisualTone.accent.tint.opacity(0.26),
                    Color.clear,
                ],
                center: .bottomTrailing,
                startRadius: 24,
                endRadius: 300
            )

            RadialGradient(
                colors: [
                    Color(red: 0.93, green: 0.76, blue: 0.68).opacity(0.18),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 14,
                endRadius: 240
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct MeetingModeGlassCard<Content: View>: View {
    let tone: MeetingModeVisualTone
    let style: MeetingModeGlassCardStyle
    let spacing: CGFloat
    let contentPadding: CGFloat
    let content: Content

    init(
        tone: MeetingModeVisualTone = .neutral,
        style: MeetingModeGlassCardStyle = .section,
        spacing: CGFloat = 12,
        contentPadding: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.style = style
        self.spacing = spacing
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(contentPadding)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(material)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(baseOverlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(style == .footer ? 0.18 : 0.42),
                                Color.white.opacity(0.10),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tone.tint.opacity(accentStrokeOpacity), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, y: shadowYOffset)
    }

    private var material: Material {
        switch style {
        case .hero:
            return .thickMaterial
        case .section:
            return .ultraThinMaterial
        case .action:
            return .thinMaterial
        case .footer:
            return .ultraThinMaterial
        }
    }

    private var baseOverlay: Color {
        switch style {
        case .hero:
            return Color.white.opacity(0.07)
        case .section:
            return Color.black.opacity(0.025)
        case .action:
            return tone.tint.opacity(0.05)
        case .footer:
            return Color.black.opacity(0.02)
        }
    }

    private var borderColor: Color {
        switch style {
        case .hero:
            return Color.white.opacity(0.28)
        case .section:
            return Color.white.opacity(0.16)
        case .action:
            return Color.white.opacity(0.22)
        case .footer:
            return Color.white.opacity(0.12)
        }
    }

    private var accentStrokeOpacity: Double {
        switch style {
        case .hero:
            return 0.18
        case .section:
            return 0.08
        case .action:
            return 0.14
        case .footer:
            return 0.06
        }
    }

    private var shadowOpacity: Double {
        switch style {
        case .hero:
            return 0.16
        case .section:
            return 0.10
        case .action:
            return 0.12
        case .footer:
            return 0.06
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .hero:
            return 22
        case .section:
            return 14
        case .action:
            return 16
        case .footer:
            return 8
        }
    }

    private var shadowYOffset: CGFloat {
        switch style {
        case .hero:
            return 14
        case .section:
            return 8
        case .action:
            return 10
        case .footer:
            return 5
        }
    }
}

struct MeetingModeSectionHeader: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MeetingModeTextPalette.secondary)
                .frame(width: 16)

            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MeetingModeTextPalette.secondary)
        }
    }
}

private struct MeetingModeInsetSurfaceModifier: ViewModifier {
    let tone: MeetingModeVisualTone
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.10),
                                        Color.clear,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(tone.tint.opacity(0.10), lineWidth: 0.8)
                    )
            )
    }
}

private struct MeetingModeActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let role: MeetingModeButtonRole
    let tone: MeetingModeVisualTone
    let fillsWidth: Bool
    let size: MeetingModeButtonSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(foregroundColor(configuration: configuration))
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(background(configuration: configuration))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor(configuration: configuration), lineWidth: borderWidth)
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed && isEnabled ? 0.988 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func background(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(baseMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundOverlay(configuration: configuration))
            )
            .shadow(
                color: shadowColor(configuration: configuration),
                radius: shadowRadius,
                y: shadowYOffset
            )
    }

    private var font: Font {
        switch size {
        case .regular:
            return .subheadline.weight(.semibold)
        case .compact:
            return .subheadline.weight(.medium)
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .regular:
            return 11
        case .compact:
            return 8
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .regular:
            return 14
        case .compact:
            return 12
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .regular:
            return 16
        case .compact:
            return 14
        }
    }

    private var borderWidth: CGFloat {
        role == .primary ? 0.8 : 0.9
    }

    private var baseMaterial: Material {
        .ultraThinMaterial
    }

    private func backgroundOverlay(configuration: Configuration) -> some ShapeStyle {
        if !isEnabled {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.06),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        switch role {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        tone.tint.opacity(configuration.isPressed ? 0.96 : 1.0),
                        tone.emphasis.opacity(configuration.isPressed ? 0.90 : 0.96),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.19, green: 0.23, blue: 0.30).opacity(configuration.isPressed ? 0.92 : 0.98),
                        tone.emphasis.opacity(configuration.isPressed ? 0.30 : 0.38),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .destructive:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        MeetingModeVisualTone.critical.tint.opacity(configuration.isPressed ? 0.94 : 1.0),
                        MeetingModeVisualTone.critical.emphasis.opacity(configuration.isPressed ? 0.88 : 0.94),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private func foregroundColor(configuration: Configuration) -> Color {
        if !isEnabled {
            return MeetingModeTextPalette.disabled
        }

        switch role {
        case .primary:
            return configuration.isPressed ? Color.white.opacity(0.94) : Color.white
        case .secondary:
            return Color.white.opacity(configuration.isPressed ? 0.92 : 0.98)
        case .destructive:
            return Color.white.opacity(configuration.isPressed ? 0.94 : 0.99)
        }
    }

    private func borderColor(configuration: Configuration) -> Color {
        if !isEnabled {
            return MeetingModeTextPalette.disabled.opacity(0.30)
        }

        switch role {
        case .primary:
            return Color.white.opacity(configuration.isPressed ? 0.24 : 0.30)
        case .secondary:
            return Color.white.opacity(configuration.isPressed ? 0.16 : 0.20)
        case .destructive:
            return Color.white.opacity(configuration.isPressed ? 0.18 : 0.24)
        }
    }

    private func shadowColor(configuration: Configuration) -> Color {
        if !isEnabled {
            return Color.black.opacity(0.04)
        }

        switch role {
        case .primary:
            return tone.emphasis.opacity(configuration.isPressed ? 0.18 : 0.24)
        case .secondary:
            return Color.black.opacity(configuration.isPressed ? 0.08 : 0.12)
        case .destructive:
            return MeetingModeVisualTone.critical.emphasis.opacity(configuration.isPressed ? 0.08 : 0.12)
        }
    }

    private var shadowRadius: CGFloat {
        switch role {
        case .primary:
            return 12
        case .secondary, .destructive:
            return 8
        }
    }

    private var shadowYOffset: CGFloat {
        switch role {
        case .primary:
            return 6
        case .secondary, .destructive:
            return 4
        }
    }
}

extension View {
    func meetingModeInsetSurface(
        tone: MeetingModeVisualTone = .neutral,
        cornerRadius: CGFloat = 14
    ) -> some View {
        modifier(MeetingModeInsetSurfaceModifier(tone: tone, cornerRadius: cornerRadius))
    }

    func meetingModeActionButton(
        tone: MeetingModeVisualTone = .accent,
        role: MeetingModeButtonRole = .secondary,
        fillsWidth: Bool = true,
        size: MeetingModeButtonSize = .regular
    ) -> some View {
        buttonStyle(
            MeetingModeActionButtonStyle(
                role: role,
                tone: tone,
                fillsWidth: fillsWidth,
                size: size
            )
        )
    }
}
