import SwiftUI

enum AppBrand {
    static let name = "Drop"
    static let tagline = "Skate lower. Feel it sooner."
}

struct DropBrandMark: View {
    var iconSize: CGFloat = 108
    var titleSize: CGFloat = 34
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            DropIcon(size: iconSize)

            VStack(spacing: 5) {
                Text(AppBrand.name)
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .tracking(1.5)

                if let subtitle {
                    Text(subtitle)
                        .font(AppType.label(14, weight: .semibold))
                        .foregroundStyle(AppTheme.inkMuted)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Icon

struct DropIcon: View {
    var size: CGFloat = 108

    var body: some View {
        ZStack {
            badge
            SunburstShape(rayCount: 16, rayWidthFraction: 0.35)
                .fill(Color.white.opacity(0.18))
                .frame(width: size * 0.82, height: size * 0.82)
            racingStripe
            skateGroup
            stars
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 0.24, green: 0.14, blue: 0.10).opacity(0.28), radius: size * 0.12, x: 0, y: size * 0.06)
        .accessibilityHidden(true)
    }

    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.91, green: 0.75, blue: 0.32),
                            Color(red: 0.84, green: 0.36, blue: 0.14),
                            Color(red: 0.58, green: 0.20, blue: 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(Color.white.opacity(0.30), lineWidth: size * 0.025)
        }
    }

    private var racingStripe: some View {
        Capsule()
            .fill(Color.white.opacity(0.22))
            .frame(width: size * 0.88, height: size * 0.055)
            .offset(y: size * 0.02)
    }

    private var skateGroup: some View {
        VStack(spacing: 0) {
            SkateBootView(size: size)
            Capsule()
                .fill(Color(red: 0.24, green: 0.14, blue: 0.10))
                .frame(width: size * 0.38, height: size * 0.032)
            SkateWheelsView(size: size)
                .padding(.top, size * 0.008)
        }
        .offset(y: size * 0.02)
    }

    private var stars: some View {
        ZStack {
            FourPointStarShape()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(x: -size * 0.32, y: -size * 0.30)
            FourPointStarShape()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: size * 0.34, y: -size * 0.28)
            FourPointStarShape()
                .fill(Color.white.opacity(0.70))
                .frame(width: size * 0.05, height: size * 0.05)
                .offset(x: size * 0.28, y: size * 0.32)
        }
    }
}

// MARK: - Skate Components

private struct SkateBootView: View {
    let size: CGFloat

    private let bootLight = Color(red: 0.98, green: 0.95, blue: 0.87)
    private let bootDark = Color(red: 0.92, green: 0.86, blue: 0.72)
    private let stripeOrange = Color(red: 0.84, green: 0.36, blue: 0.14)
    private let stripeTeal = Color(red: 0.36, green: 0.58, blue: 0.56)
    private let laceColor = Color(red: 0.24, green: 0.14, blue: 0.10)

    var body: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: size * 0.12,
                bottomLeadingRadius: size * 0.04,
                bottomTrailingRadius: size * 0.04,
                topTrailingRadius: size * 0.06
            )
            .fill(LinearGradient(colors: [bootLight, bootDark], startPoint: .top, endPoint: .bottom))
            .frame(width: size * 0.34, height: size * 0.24)

            stripes
            laces
        }
    }

    private var stripes: some View {
        VStack(spacing: size * 0.02) {
            Capsule().fill(stripeOrange).frame(width: size * 0.28, height: size * 0.030)
            Capsule().fill(stripeTeal).frame(width: size * 0.28, height: size * 0.022)
        }
        .offset(y: size * 0.03)
    }

    private var laces: some View {
        HStack(spacing: size * 0.022) {
            Circle().fill(laceColor.opacity(0.40)).frame(width: size * 0.022, height: size * 0.022)
            Circle().fill(laceColor.opacity(0.40)).frame(width: size * 0.022, height: size * 0.022)
            Circle().fill(laceColor.opacity(0.40)).frame(width: size * 0.022, height: size * 0.022)
        }
        .offset(y: -size * 0.07)
    }
}

private struct SkateWheelsView: View {
    let size: CGFloat

    private let amber = Color(red: 0.92, green: 0.58, blue: 0.18)
    private let dark = Color(red: 0.24, green: 0.14, blue: 0.10)
    private let cream = Color(red: 0.98, green: 0.95, blue: 0.87)

    var body: some View {
        HStack(spacing: size * 0.055) {
            wheel
            wheel
            wheel
            wheel
        }
    }

    private var wheel: some View {
        ZStack {
            Circle().fill(amber)
            Circle().stroke(dark, lineWidth: size * 0.010)
            Circle().fill(cream).frame(width: size * 0.035, height: size * 0.035)
        }
        .frame(width: size * 0.09, height: size * 0.09)
    }
}

// MARK: - Shapes

private struct SunburstShape: Shape {
    let rayCount: Int
    let rayWidthFraction: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: Double = min(rect.width, rect.height) / 2
        let angleStep: Double = .pi * 2 / Double(rayCount)
        let halfRay: Double = angleStep * rayWidthFraction

        var path = Path()
        for i in 0..<rayCount {
            let angle: Double = Double(i) * angleStep - .pi / 2
            path.move(to: center)
            path.addLine(to: CGPoint(
                x: center.x + Foundation.cos(angle - halfRay) * radius,
                y: center.y + Foundation.sin(angle - halfRay) * radius
            ))
            path.addLine(to: CGPoint(
                x: center.x + Foundation.cos(angle + halfRay) * radius,
                y: center.y + Foundation.sin(angle + halfRay) * radius
            ))
            path.closeSubpath()
        }
        return path
    }
}

private struct FourPointStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer: Double = min(rect.width, rect.height) / 2
        let inner: Double = outer * 0.38
        let points = 4

        var path = Path()
        for i in 0..<(points * 2) {
            let angle: Double = Double(i) * .pi / Double(points) - .pi / 2
            let r: Double = i.isMultiple(of: 2) ? outer : inner
            let pt = CGPoint(x: center.x + Foundation.cos(angle) * r, y: center.y + Foundation.sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
