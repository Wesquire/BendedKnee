import SwiftUI

struct BendedKneeBrandMark: View {
    var iconSize: CGFloat = 108
    var titleSize: CGFloat = 34
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 18) {
            BendedKneeIcon(size: iconSize)

            VStack(spacing: 6) {
                Text("Bended Knee")
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

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

struct BendedKneeIcon: View {
    var size: CGFloat = 108

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.panelStrong, AppTheme.sand, AppTheme.mist],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(AppTheme.line.opacity(0.85), lineWidth: size * 0.03)

            bentLeg
                .stroke(AppTheme.deepForest, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.64, height: size * 0.64)
                .offset(x: -size * 0.03, y: -size * 0.12)

            skate
                .frame(width: size * 0.56, height: size * 0.38)
                .offset(x: size * 0.05, y: size * 0.16)
        }
        .frame(width: size, height: size)
        .shadow(color: AppTheme.deepForest.opacity(0.14), radius: 16, x: 0, y: 10)
        .accessibilityHidden(true)
    }

    private var bentLeg: Path {
        Path { path in
            path.move(to: CGPoint(x: 0.22, y: 0.18))
            path.addQuadCurve(to: CGPoint(x: 0.43, y: 0.40), control: CGPoint(x: 0.36, y: 0.18))
            path.addQuadCurve(to: CGPoint(x: 0.69, y: 0.58), control: CGPoint(x: 0.55, y: 0.58))
        }
    }

    private var skate: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.40, height: size * 0.18)
                .rotationEffect(.degrees(-10))
                .offset(y: -size * 0.06)
                .overlay(alignment: .topLeading) {
                    Capsule()
                        .fill(Color.white.opacity(0.36))
                        .frame(width: size * 0.18, height: size * 0.03)
                        .offset(x: size * 0.09, y: size * 0.05)
                        .rotationEffect(.degrees(-10))
                }

            Capsule()
                .fill(AppTheme.deepForest)
                .frame(width: size * 0.42, height: size * 0.04)

            HStack(spacing: size * 0.05) {
                wheel
                wheel
                wheel
                wheel
            }
            .offset(y: size * 0.08)
        }
    }

    private var wheel: some View {
        ZStack {
            Circle()
                .fill(AppTheme.deepForest)
            Circle()
                .fill(AppTheme.panelStrong)
                .frame(width: size * 0.06, height: size * 0.06)
        }
        .frame(width: size * 0.11, height: size * 0.11)
    }
}
