import SwiftUI

enum AppTheme {
    static let paper = Color(red: 0.95, green: 0.93, blue: 0.88)
    static let sand = Color(red: 0.90, green: 0.85, blue: 0.74)
    static let mist = Color(red: 0.78, green: 0.86, blue: 0.85)
    static let ink = Color(red: 0.11, green: 0.16, blue: 0.20)
    static let mutedInk = Color(red: 0.34, green: 0.40, blue: 0.43)
    static let slate = Color(red: 0.19, green: 0.28, blue: 0.30)
    static let accent = Color(red: 0.82, green: 0.46, blue: 0.18)
    static let accentSoft = Color(red: 0.90, green: 0.72, blue: 0.45)
    static let success = Color(red: 0.34, green: 0.75, blue: 0.56)
    static let warning = Color(red: 0.92, green: 0.63, blue: 0.31)
    static let danger = Color(red: 0.88, green: 0.36, blue: 0.29)
    static let panel = Color(red: 0.99, green: 0.97, blue: 0.94)
    static let panelStrong = Color(red: 0.97, green: 0.94, blue: 0.89)
    static let panelSecondary = Color(red: 0.96, green: 0.93, blue: 0.88)
    static let line = Color.white.opacity(0.72)
    static let deepForest = Color(red: 0.13, green: 0.22, blue: 0.22)
    static let inkMuted = mutedInk

    static let homeBackground = LinearGradient(
        colors: [paper, sand, mist],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sessionBackground = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.10, blue: 0.11),
            Color(red: 0.10, green: 0.18, blue: 0.17),
            Color(red: 0.16, green: 0.15, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum AppType {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct PrimaryFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.95 : 1)
    }
}
