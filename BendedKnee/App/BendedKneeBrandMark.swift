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
        Image("DropIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: Color(red: 0.24, green: 0.14, blue: 0.10).opacity(0.28), radius: size * 0.12, x: 0, y: size * 0.06)
            .accessibilityHidden(true)
    }
}

// MARK: - Shapes

struct SunburstShape: Shape {
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

