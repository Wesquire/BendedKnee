import SwiftUI

enum AppTheme {

    // MARK: - Poster Layer (backgrounds, large surfaces)

    static let posterCream = Color(red: 0.99, green: 0.96, blue: 0.84)  // #FDF5D7
    static let posterGold  = Color(red: 0.96, green: 0.71, blue: 0.09)  // #F5B518
    static let posterCoral = Color(red: 0.91, green: 0.29, blue: 0.18)  // #E84A2E
    static let posterTeal  = Color(red: 0.07, green: 0.59, blue: 0.57)  // #129791
    static let posterBlue  = Color(red: 0.10, green: 0.23, blue: 0.52)  // #1A3B85
    static let posterPlum  = Color(red: 0.41, green: 0.11, blue: 0.31)  // #691C4F

    // MARK: - Neon Layer (data, numbers, interactive elements on dark surfaces)

    static let neonGold  = Color(red: 1.00, green: 0.84, blue: 0.31)  // #FFD54F
    static let neonCoral = Color(red: 1.00, green: 0.42, blue: 0.29)  // #FF6B4A
    static let neonTeal  = Color(red: 0.00, green: 0.90, blue: 0.80)  // #00E5CC

    // MARK: - Ink Layer (text, borders)

    static let deepInk   = Color(red: 0.10, green: 0.05, blue: 0.06)  // #1A0C10
    static let mutedInk  = Color(red: 0.29, green: 0.17, blue: 0.14)  // #4A2A24
    static let faintInk  = Color(red: 0.42, green: 0.28, blue: 0.25).opacity(0.50) // #6B4840 50%

    // MARK: - Semantic Aliases (backward compatibility)

    static let ink          = deepInk
    static let inkMuted     = mutedInk
    static let accent       = posterCoral
    static let accentSoft   = posterGold
    static let slate        = posterBlue
    static let deepForest   = deepInk
    static let success      = neonTeal
    static let warning      = posterGold
    static let danger       = Color(red: 0.76, green: 0.08, blue: 0.18)

    // MARK: - Panels

    static let panel          = Color.white.opacity(0.88)
    static let panelStrong    = Color.white.opacity(0.92)
    static let panelSecondary = Color.white.opacity(0.70)
    static let line           = Color.white.opacity(0.52)

    // MARK: - Gradients

    static let homeBackground = LinearGradient(
        colors: [posterCream, posterGold, posterCoral],
        startPoint: .top,
        endPoint: .bottom
    )

    static let sessionBackground = LinearGradient(
        colors: [posterPlum, posterBlue, deepInk],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum PosterBackdropStyle {
    case warm
    case home
    case session
}

struct PosterBackdrop: View {
    let style: PosterBackdropStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            staticBackdrop
        } else {
            livingBackdrop
        }
    }

    // MARK: - Living version (drifting blobs)

    private var livingBackdrop: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GeometryReader { geometry in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = geometry.size.width
                let h = geometry.size.height

                ZStack {
                    backgroundGradient

                    stripeField(width: w, height: h)
                        .blendMode(.softLight)
                        .opacity(style == .session ? 0.30 : 0.50)

                    // Blob 1 — warm gold, slow orbit upper-right
                    Circle()
                        .fill(blobColor1.opacity(style == .session ? 0.12 : 0.22))
                        .frame(width: w * 0.6, height: w * 0.6)
                        .blur(radius: 40)
                        .offset(
                            x: w * 0.22 + CGFloat(sin(t * 0.08)) * w * 0.12,
                            y: -h * 0.18 + CGFloat(cos(t * 0.06)) * h * 0.08
                        )

                    // Blob 2 — coral/teal, slow drift lower-left
                    Circle()
                        .fill(blobColor2.opacity(style == .session ? 0.10 : 0.18))
                        .frame(width: w * 0.55, height: w * 0.55)
                        .blur(radius: 36)
                        .offset(
                            x: -w * 0.20 + CGFloat(cos(t * 0.07)) * w * 0.10,
                            y: h * 0.22 + CGFloat(sin(t * 0.05)) * h * 0.10
                        )

                    // Blob 3 — cream accent, gentle wander center
                    Circle()
                        .fill(blobColor3.opacity(style == .session ? 0.06 : 0.14))
                        .frame(width: w * 0.45, height: w * 0.45)
                        .blur(radius: 28)
                        .offset(
                            x: CGFloat(sin(t * 0.05 + 2.0)) * w * 0.15,
                            y: CGFloat(cos(t * 0.04 + 1.0)) * h * 0.12
                        )
                }
                .clipped()
            }
        }
    }

    // MARK: - Static fallback (Reduce Motion)

    private var staticBackdrop: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient

                stripeField(width: geometry.size.width, height: geometry.size.height)
                    .blendMode(.softLight)
                    .opacity(style == .session ? 0.30 : 0.50)

                Circle()
                    .fill(blobColor1.opacity(style == .session ? 0.12 : 0.20))
                    .frame(width: geometry.size.width * 0.56, height: geometry.size.width * 0.56)
                    .blur(radius: 36)
                    .offset(x: geometry.size.width * 0.24, y: -geometry.size.height * 0.20)

                Circle()
                    .fill(blobColor2.opacity(style == .session ? 0.10 : 0.16))
                    .frame(width: geometry.size.width * 0.50, height: geometry.size.width * 0.50)
                    .blur(radius: 32)
                    .offset(x: -geometry.size.width * 0.22, y: geometry.size.height * 0.24)
            }
            .clipped()
        }
    }

    // MARK: - Shared components

    private var blobColor1: Color {
        style == .session ? AppTheme.posterPlum : AppTheme.posterGold
    }

    private var blobColor2: Color {
        style == .session ? Color(red: 0.06, green: 0.12, blue: 0.36) : AppTheme.posterTeal
    }

    private var blobColor3: Color {
        style == .session ? AppTheme.posterPlum.opacity(0.5) : AppTheme.posterCream
    }

    private var backgroundGradient: some View {
        switch style {
        case .warm:
            return AnyView(
                LinearGradient(
                    colors: [AppTheme.posterCream, AppTheme.posterGold, AppTheme.posterCoral],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .home:
            return AnyView(AppTheme.homeBackground)
        case .session:
            return AnyView(AppTheme.sessionBackground)
        }
    }

    private func stripeField(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(0..<14, id: \.self) { index in
                Rectangle()
                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.14) : Color.black.opacity(0.06))
                    .frame(width: width * 1.6, height: max(20, height * 0.040))
                    .rotationEffect(.degrees(-24))
                    .offset(y: CGFloat(index) * height * 0.085 - height * 0.42)
            }
        }
    }
}

/// Unified type scale — all SF Rounded, 6 strict levels.
enum AppType {
    /// 160pt black — session angle number only
    static let metric = Font.system(size: 160, weight: .black, design: .rounded)

    /// 64pt black — home gauge number
    static let displayLarge = Font.system(size: 64, weight: .black, design: .rounded)

    /// Flexible display size (for responsive scaling)
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    /// 24pt black — section headings
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    /// Poster title (same as title — serif removed)
    static func posterTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    /// 16pt semibold — primary text / 13pt bold — buttons, captions
    static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// 11pt bold — eyebrows, badges, micro labels
    static let micro = Font.system(size: 11, weight: .bold, design: .rounded)
}

struct PrimaryFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}
