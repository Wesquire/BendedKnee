import SwiftUI

enum AppTheme {
    static let posterCream = Color(red: 0.99, green: 0.95, blue: 0.84)
    static let posterGold = Color(red: 0.97, green: 0.71, blue: 0.18)
    static let posterCoral = Color(red: 0.91, green: 0.29, blue: 0.18)
    static let posterTeal = Color(red: 0.07, green: 0.59, blue: 0.57)
    static let posterBlue = Color(red: 0.10, green: 0.23, blue: 0.52)
    static let posterPlum = Color(red: 0.41, green: 0.11, blue: 0.31)
    static let deepInk = Color(red: 0.16, green: 0.08, blue: 0.10)

    static let paper = posterCream
    static let sand = posterGold
    static let mist = posterTeal
    static let ink = deepInk
    static let mutedInk = Color(red: 0.37, green: 0.21, blue: 0.18)
    static let slate = posterBlue
    static let inkMuted = mutedInk
    static let accent = posterCoral
    static let accentSoft = posterGold
    static let success = Color(red: 0.27, green: 0.68, blue: 0.38)
    static let warning = Color(red: 0.98, green: 0.74, blue: 0.18)
    static let danger = Color(red: 0.76, green: 0.08, blue: 0.18)
    static let panel = Color.white.opacity(0.78)
    static let panelStrong = Color.white.opacity(0.86)
    static let panelSecondary = Color.white.opacity(0.74)
    static let line = Color.white.opacity(0.52)
    static let deepForest = deepInk

    static let homeBackground = LinearGradient(
        colors: [posterGold, posterCoral, posterTeal, posterCream],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient

                SunburstShape(rayCount: 18, rayWidthFraction: 0.52)
                    .fill(Color.white.opacity(style == .session ? 0.08 : 0.14))
                    .frame(width: geometry.size.width * 1.25, height: geometry.size.width * 1.25)
                    .offset(x: geometry.size.width * 0.38, y: -geometry.size.height * 0.28)

                stripeField(width: geometry.size.width, height: geometry.size.height)
                    .blendMode(.softLight)
                    .opacity(style == .session ? 0.40 : 0.58)

                Circle()
                    .fill(AppTheme.posterCream.opacity(style == .session ? 0.10 : 0.16))
                    .frame(width: geometry.size.width * 0.56, height: geometry.size.width * 0.56)
                    .blur(radius: 16)
                    .offset(x: -geometry.size.width * 0.30, y: geometry.size.height * 0.26)

                Circle()
                    .fill(AppTheme.posterGold.opacity(style == .session ? 0.10 : 0.20))
                    .frame(width: geometry.size.width * 0.46, height: geometry.size.width * 0.46)
                    .blur(radius: 12)
                    .offset(x: geometry.size.width * 0.28, y: geometry.size.height * 0.30)
            }
            .clipped()
        }
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
                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.16) : Color.black.opacity(0.08))
                    .frame(width: width * 1.6, height: max(24, height * 0.045))
                    .rotationEffect(.degrees(-24))
                    .offset(y: CGFloat(index) * height * 0.085 - height * 0.42)
            }
        }
    }
}

enum AppType {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func posterTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct PrimaryFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}
