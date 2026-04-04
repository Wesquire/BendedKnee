import SwiftUI

struct ArcGaugeView: View {
    let currentAngle: Double
    let targetAngle: Double
    let zone: HapticZone
    let isPaused: Bool
    var numberSize: CGFloat = 140
    var arcDiameter: CGFloat = 280
    var strokeWidth: CGFloat = 3.5
    var showTargetLabel: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var zonePulse = false

    private var progress: Double {
        guard targetAngle > 0 else { return 1 }
        return min(max(currentAngle / targetAngle, 0), 1)
    }

    private var zoneColor: Color {
        if isPaused { return Color.white.opacity(0.25) }
        switch zone {
        case .none:   return Color(red: 1.0, green: 0.84, blue: 0.31)  // neon gold
        case .gentle: return Color(red: 0.99, green: 0.95, blue: 0.84) // warm cream
        case .medium: return Color(red: 1.0, green: 0.42, blue: 0.29)  // neon coral
        case .strong: return Color(red: 0.94, green: 0.22, blue: 0.14) // hot red
        }
    }

    /// Breathing cycle duration — syncs with haptic interval
    private var breathCycle: Double {
        switch zone {
        case .none:   return 0    // steady, no breathing — the reward
        case .gentle: return 3.0  // slow, calm breath
        case .medium: return 1.8  // quicker
        case .strong: return 1.0  // urgent
        }
    }

    var body: some View {
        let shouldBreathe = !isPaused && !reduceMotion && breathCycle > 0

        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !shouldBreathe)) { timeline in
            let t = shouldBreathe ? timeline.date.timeIntervalSinceReferenceDate : 0
            let breathPhase = breathCycle > 0 ? sin(t * .pi * 2.0 / breathCycle) : 0
            let glowRadius: CGFloat = shouldBreathe ? CGFloat(8 + breathPhase * 4) : 8
            let glowOpacity: Double = shouldBreathe ? 0.45 + breathPhase * 0.15 : 0.55

            let highContrast = contrast == .increased
            let arcStroke = highContrast ? strokeWidth * 1.5 : strokeWidth

            ZStack {
                // Track (empty arc)
                ArcShape(progress: 1.0)
                    .stroke(Color.white.opacity(highContrast ? 0.20 : 0.08), style: StrokeStyle(lineWidth: arcStroke, lineCap: .round))
                    .frame(width: arcDiameter, height: arcDiameter)

                // Filled arc with breathing glow
                ArcShape(progress: isPaused ? 0.12 : progress)
                    .stroke(zoneColor, style: StrokeStyle(lineWidth: arcStroke, lineCap: .round))
                    .frame(width: arcDiameter, height: arcDiameter)
                    .shadow(color: highContrast ? .clear : zoneColor.opacity(glowOpacity), radius: glowRadius)
                    .animation(.easeInOut(duration: 0.4), value: progress)

                // Number + target label
                VStack(spacing: 6) {
                    NeonNumberView(
                        text: isPaused ? "—" : "\(Int(currentAngle.rounded()))",
                        color: zoneColor,
                        size: numberSize,
                        dimmed: isPaused,
                        highContrast: highContrast
                    )
                    .scaleEffect(zonePulse ? 1.04 : 1.0)
                    .accessibilityIdentifier("sessionAngleText")

                    if showTargetLabel {
                        Text("TARGET \(Int(targetAngle.rounded()))°")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(2.0)
                            .foregroundStyle(Color.white.opacity(isPaused ? 0.20 : 0.50))
                    }
                }
            }
        }
        .onChange(of: zone) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                zonePulse = true
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.15)) {
                zonePulse = false
            }
        }
    }
}

// MARK: - Neon Number

struct NeonNumberView: View {
    let text: String
    let color: Color
    var size: CGFloat = 140
    var dimmed: Bool = false
    var highContrast: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(dimmed ? color.opacity(0.12) : color)
            .shadow(color: (dimmed || highContrast) ? .clear : color.opacity(0.60), radius: 6, x: 0, y: 0)
            .shadow(color: (dimmed || highContrast) ? .clear : color.opacity(0.35), radius: 16, x: 0, y: 0)
            .shadow(color: (dimmed || highContrast) ? .clear : color.opacity(0.15), radius: 32, x: 0, y: 0)
            .minimumScaleFactor(0.45)
            .lineLimit(1)
    }
}

// MARK: - Arc Shape (270-degree sweep)

struct ArcShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let startAngle: Angle = .degrees(135)
        let fullSweep: Double = 270
        let endAngle: Angle = .degrees(135 + fullSweep * min(max(progress, 0), 1))

        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
