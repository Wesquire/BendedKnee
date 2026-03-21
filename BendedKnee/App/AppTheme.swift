import SwiftUI

// MARK: - 70's Retro Roller Rink Palette
// Groovy but not cartoonish — warm mustard, burnt sienna, teal, chocolate, cream.

enum AppTheme {
    // Primary surfaces
    static let paper = Color(red: 0.98, green: 0.95, blue: 0.87)        // warm cream
    static let sand = Color(red: 0.91, green: 0.75, blue: 0.32)         // mustard gold
    static let mist = Color(red: 0.36, green: 0.58, blue: 0.56)         // retro teal

    // Text
    static let ink = Color(red: 0.18, green: 0.12, blue: 0.09)          // dark chocolate
    static let mutedInk = Color(red: 0.44, green: 0.32, blue: 0.24)     // warm brown
    static let slate = Color(red: 0.26, green: 0.40, blue: 0.38)        // dark teal
    static let inkMuted = mutedInk

    // Accent — burnt sienna / orange
    static let accent = Color(red: 0.82, green: 0.34, blue: 0.12)       // burnt sienna
    static let accentSoft = Color(red: 0.92, green: 0.58, blue: 0.18)   // warm amber

    // Semantic
    static let success = Color(red: 0.38, green: 0.56, blue: 0.30)      // olive green
    static let warning = Color(red: 0.88, green: 0.62, blue: 0.14)      // golden warning
    static let danger = Color(red: 0.74, green: 0.22, blue: 0.14)       // deep red

    // Panels — warm creams and tans
    static let panel = Color(red: 0.99, green: 0.96, blue: 0.89)        // lightest cream
    static let panelStrong = Color(red: 0.97, green: 0.92, blue: 0.80)  // warm tan
    static let panelSecondary = Color(red: 0.96, green: 0.90, blue: 0.77) // deeper tan
    static let line = Color.white.opacity(0.68)

    // Deep tones
    static let deepForest = Color(red: 0.24, green: 0.14, blue: 0.10)   // chocolate brown

    // Gradients
    static let homeBackground = LinearGradient(
        colors: [
            paper,
            Color(red: 0.96, green: 0.88, blue: 0.68),  // warm gold wash
            mist.opacity(0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sessionBackground = LinearGradient(
        colors: [
            Color(red: 0.14, green: 0.09, blue: 0.07),  // near-black chocolate
            Color(red: 0.26, green: 0.15, blue: 0.08),   // dark burnt umber
            Color(red: 0.16, green: 0.24, blue: 0.22)    // dark teal shadow
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
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}
