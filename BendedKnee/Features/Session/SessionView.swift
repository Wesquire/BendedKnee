import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        GeometryReader { geometry in
            let angleFontSize: CGFloat = min(104, geometry.size.width * 0.24)
            let contentWidth = min(geometry.size.width - 24, 560)

            ZStack {
                AppTheme.sessionBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        VStack(spacing: 10) {
                            HStack {
                                Text(AppBrand.name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.70))

                                Spacer()
                            }

                            stateBadge

                            Text(viewModel.currentAngleText)
                                .font(.system(size: angleFontSize, weight: .black, design: .rounded))
                                .foregroundStyle(angleColor)
                                .monospacedDigit()
                                .minimumScaleFactor(0.55)
                                .opacity(viewModel.sessionPhase == .pausedPocketRemoved ? 0.18 : 1)
                                .accessibilityIdentifier("sessionAngleText")

                            Text("Target \(viewModel.targetAngleText)")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(viewModel.sessionPhase == .pausedPocketRemoved ? 0.24 : 0.75))
                        }

                        progressPanel

                        if viewModel.sessionPhase == .pausedPocketRemoved {
                            pausedBanner
                        }

                        Text(viewModel.primarySessionTitle)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(viewModel.sessionPhase == .pausedPocketRemoved ? .white : angleColor)
                            .accessibilityIdentifier("sessionStatusText")

                        Text(viewModel.primarySessionDetail)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.white.opacity(viewModel.sessionPhase == .pausedPocketRemoved ? 0.92 : 0.78))
                            .padding(.horizontal, 18)

                        Text("Need a new target? End the session and change it in setup before skating again.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.white.opacity(0.62))
                            .padding(.horizontal, 24)

                        Button(action: viewModel.stopSession) {
                            Text("End Session")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.14))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .accessibilityIdentifier("endSessionButton")

                        Spacer(minLength: 12)
                    }
                    .frame(maxWidth: contentWidth)
                    .padding(.horizontal, 12)
                    .padding(.top, max(geometry.safeAreaInsets.top, 12) + 12)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16) + 8)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var angleColor: Color {
        if viewModel.sessionPhase == .pausedPocketRemoved {
            return Color.white.opacity(0.55)
        }

        let deficit = max(0, viewModel.settings.targetAngle - viewModel.currentAngle)
        switch HapticZone.zone(for: deficit) {
        case .none:
            return AppTheme.success
        case .gentle:
            return AppTheme.warning
        case .medium:
            return AppTheme.accent
        case .strong:
            return AppTheme.danger
        }
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(viewModel.sessionPhase == .pausedPocketRemoved ? "Session Paused" : "Target Progress")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                Spacer()
                Text(viewModel.sessionPhase == .pausedPocketRemoved ? "WAITING" : "\(Int((viewModel.targetProgress * 100).rounded()))%")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(angleColor)
                        .frame(width: max(24, proxy.size.width * max(viewModel.targetProgress, viewModel.sessionPhase == .pausedPocketRemoved ? 0.12 : 0)))
                }
            }
            .frame(height: 12)

            Text(viewModel.sessionPhase == .pausedPocketRemoved ? "Return the phone to your front pocket to resume coaching." : "This session view stays awake so motion tracking and haptics remain active.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(viewModel.sessionPhase == .pausedPocketRemoved ? 0.10 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var stateBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.sessionBadgeSymbol)
                .font(.system(size: 13, weight: .bold))
            Text(viewModel.sessionBadgeText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .accessibilityElement(children: .combine)
        .foregroundStyle(sessionBadgeForeground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(sessionBadgeBackground))
        .accessibilityIdentifier("sessionStateBadge")
    }

    private var pausedBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Phone Removed")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Return the phone to your front pocket to resume haptic coaching.")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.86))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
        )
        .accessibilityIdentifier("pausedPocketRemovedBanner")
    }

    private var sessionBadgeForeground: Color {
        switch viewModel.sessionPhase {
        case .pausedPocketRemoved:
            return .white
        case .running:
            return viewModel.targetProgress >= 1 ? AppTheme.success : AppTheme.warning
        default:
            return .white
        }
    }

    private var sessionBadgeBackground: Color {
        switch viewModel.sessionPhase {
        case .pausedPocketRemoved:
            return Color.white.opacity(0.14)
        case .running:
            return (viewModel.targetProgress >= 1 ? AppTheme.success : AppTheme.warning).opacity(0.18)
        default:
            return Color.white.opacity(0.10)
        }
    }
}
