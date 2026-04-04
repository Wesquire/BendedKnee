import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel

    private var zone: HapticZone {
        HapticZone.zone(for: max(0, viewModel.settings.targetAngle - viewModel.currentAngle))
    }

    private var isPaused: Bool {
        viewModel.sessionPhase == .pausedPocketRemoved
    }

    var body: some View {
        GeometryReader { geometry in
            let gaugeSize = min(geometry.size.width * 0.78, 340)
            let numberSize = min(geometry.size.width * 0.38, 160)

            ZStack {
                // 1.4: Near-black background with subtle plum glow
                Color(red: 0.03, green: 0.03, blue: 0.05)
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        Color(red: 0.28, green: 0.08, blue: 0.22).opacity(0.30),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.6
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar: brand + state badge
                    HStack {
                        Text(AppBrand.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.45))

                        Spacer()

                        stateBadge
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 4)

                    Spacer()

                    // Center: the arc gauge with neon number
                    ArcGaugeView(
                        currentAngle: viewModel.currentAngle,
                        targetAngle: viewModel.settings.targetAngle,
                        zone: zone,
                        isPaused: isPaused,
                        numberSize: numberSize,
                        arcDiameter: gaugeSize
                    )

                    Spacer()

                    // Status label — one line, zone color
                    if isPaused {
                        pausedSection
                    } else {
                        Text(zone.label)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(zoneColor)
                            .accessibilityIdentifier("sessionStatusText")

                        Text("Coaching continues even if the screen locks.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.40))
                            .padding(.top, 4)
                    }

                    Spacer()

                    // End session button — low contrast, bottom
                    Button(action: viewModel.stopSession) {
                        Text("End Session")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .frame(maxWidth: 200)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .foregroundStyle(Color.white.opacity(0.50))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .accessibilityIdentifier("endSessionButton")
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var zoneColor: Color {
        if isPaused { return Color.white.opacity(0.55) }
        switch zone {
        case .none:   return Color(red: 1.0, green: 0.84, blue: 0.31)
        case .gentle: return Color(red: 0.99, green: 0.95, blue: 0.84)
        case .medium: return Color(red: 1.0, green: 0.42, blue: 0.29)
        case .strong: return Color(red: 0.94, green: 0.22, blue: 0.14)
        }
    }

    private var stateBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isPaused ? Color.white.opacity(0.40) : zoneColor)
                .frame(width: 8, height: 8)
            Text(isPaused ? "Paused" : (viewModel.targetProgress >= 1 ? "On Target" : "Coaching"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.60))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .accessibilityIdentifier("sessionStateBadge")
    }

    private var pausedSection: some View {
        VStack(spacing: 8) {
            Text("Phone Removed")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.70))
                .accessibilityIdentifier("sessionStatusText")

            Text("Return the phone to your pocket to resume.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .accessibilityIdentifier("pausedPocketRemovedBanner")
    }
}
