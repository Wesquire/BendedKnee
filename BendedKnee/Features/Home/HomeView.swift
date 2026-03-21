import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var showingSkatingSetup = false

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width - 24, 640)

            ZStack {
                AppTheme.homeBackground.ignoresSafeArea()

                Circle()
                    .fill(AppTheme.accentSoft.opacity(0.18))
                    .frame(width: geometry.size.width * 0.55, height: geometry.size.width * 0.55)
                    .blur(radius: 14)
                    .offset(x: geometry.size.width * 0.35, y: -geometry.size.height * 0.32)

                Circle()
                    .fill(AppTheme.mist.opacity(0.30))
                    .frame(width: geometry.size.width * 0.48, height: geometry.size.width * 0.48)
                    .blur(radius: 16)
                    .offset(x: -geometry.size.width * 0.32, y: geometry.size.height * 0.34)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        heroCard
                        setupGuideCard
                        calibrationCard
                        SettingsCard(viewModel: viewModel)
                    }
                    .frame(maxWidth: contentWidth)
                    .padding(.horizontal, 12)
                    .padding(.top, max(geometry.safeAreaInsets.top, 12) + 8)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16) + 8)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.setupSummaryTitle.uppercased())
                .font(AppType.label(12, weight: .bold))
                .foregroundStyle(AppTheme.inkMuted)
                .tracking(1.2)

            Text(viewModel.setupSummaryDetail)
                .font(AppType.label(16, weight: .semibold))
                .foregroundStyle(viewModel.baselineAngle == nil ? AppTheme.ink : AppTheme.inkMuted)

            if let baselineAngle = viewModel.baselineAngle {
                Text("Your live number tracks extra bend beyond standing.")
                    .font(AppType.label(14, weight: .semibold))
                    .foregroundStyle(AppTheme.inkMuted)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live bend")
                            .font(AppType.label(14, weight: .bold))
                            .foregroundStyle(AppTheme.inkMuted)
                        Text(viewModel.currentAngleText)
                            .font(AppType.display(64))
                            .minimumScaleFactor(0.55)
                            .foregroundStyle(AppTheme.ink)
                            .accessibilityIdentifier("currentAngleText")
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target")
                            .font(AppType.label(14, weight: .bold))
                            .foregroundStyle(AppTheme.inkMuted)
                        Text(viewModel.targetAngleText)
                            .font(AppType.display(32))
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                Text("Standing baseline \(Int(baselineAngle.rounded()))°. The session view will coach you only when you rise too upright.")
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            } else {
                Text("Fine-tune your pocket side and target, then run an upright calibration before you skate.")
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            }

            Text(viewModel.statusText)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(statusBackground))
                .foregroundStyle(statusColor)
                .accessibilityIdentifier("statusText")

            Text(viewModel.guidanceText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.inkMuted)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.deepForest.opacity(0.08), radius: 20, x: 0, y: 10)
    }

    private var setupGuideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                    showingSkatingSetup.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Skating Setup")
                            .font(AppType.title(22))
                            .foregroundStyle(AppTheme.ink)

                        Text("Placement rules and the exact setup order.")
                            .font(AppType.label(13, weight: .semibold))
                            .foregroundStyle(AppTheme.inkMuted)
                    }

                    Spacer()

                    Image(systemName: showingSkatingSetup ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("skatingSetupDisclosure")

            if showingSkatingSetup {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Placement")
                            .font(AppType.label(13, weight: .bold))
                            .foregroundStyle(AppTheme.inkMuted)

                        Label("Use your \(viewModel.settings.pocketSide.rawValue.lowercased()) front pocket every time.", systemImage: "figure.walk")
                        Label("Keep the phone top-up.", systemImage: "arrow.up")
                        Label("Keep the screen facing your thigh.", systemImage: "iphone")
                        Label("Keep the app open and in the foreground while skating.", systemImage: "lock.open")
                    }
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)

                    Divider()
                        .overlay(AppTheme.line)

                    Text("Setup order: choose pocket side, choose target bend, calibrate upright, then start your session.")
                        .font(AppType.label(14, weight: .semibold))
                        .foregroundStyle(AppTheme.deepForest)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.panelSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.deepForest.opacity(0.06), radius: 18, x: 0, y: 10)
    }

    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.setupStepTitle)
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            Text("Tap calibrate, place the phone in your \(viewModel.settings.pocketSide.rawValue.lowercased()) front pocket during the 7-second prep countdown, then stand upright and still for the capture.")
                .font(AppType.label(15, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)

            Text("Calibration uses a 7-second prep countdown and a capture window so the phone can settle before the standing baseline is locked.")
                .font(AppType.label(13, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)

            if viewModel.shouldShowPlacementWarning {
                Label("Phone placement looks off. Keep it top-up with the screen against your thigh before you continue.", systemImage: "exclamationmark.triangle.fill")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.danger.opacity(0.10))
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.calibrationBannerTitle)
                    .font(AppType.label(14, weight: .bold))
                    .foregroundStyle(AppTheme.ink)

                Text(viewModel.calibrationBannerDetail)
                    .font(AppType.label(13, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(calibrationBannerBackground)
            )

            if case .calibrating(let secondsRemaining) = viewModel.sessionPhase {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.calibrationStage == .preparing ? "timer" : "dot.radiowaves.left.and.right")
                    Text(viewModel.calibrationStage == .preparing ? "Get Ready: \(secondsRemaining)" : "Calibrating: \(secondsRemaining)")
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.accent)
            }

            Button(action: viewModel.beginCalibration) {
                Text(viewModel.baselineAngle == nil ? "Calibrate Standing Position" : "Recalibrate Standing Position")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PrimaryFilledButtonStyle())
            .disabled(isUnavailable)
            .opacity(isUnavailable ? 0.4 : 1)
            .accessibilityIdentifier("calibrateButton")

            Text(viewModel.startSessionHelperText)
                .font(AppType.label(13, weight: .semibold))
                .foregroundStyle(viewModel.placementInvalid ? AppTheme.danger : AppTheme.inkMuted)

            Button(action: viewModel.startSession) {
                Text("Start Session")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.deepForest)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PrimaryFilledButtonStyle())
            .disabled(!viewModel.canStartSession)
            .opacity(viewModel.canStartSession ? 1 : 0.4)
            .accessibilityIdentifier("startSessionButton")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.panelSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.deepForest.opacity(0.06), radius: 18, x: 0, y: 10)
    }

    private var statusColor: Color {
        switch HapticZone.zone(for: max(0, viewModel.settings.targetAngle - viewModel.currentAngle)) {
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

    private var statusBackground: Color {
        statusColor.opacity(0.14)
    }

    private var calibrationBannerBackground: Color {
        switch viewModel.calibrationFeedbackStyle {
        case .success:
            return AppTheme.success.opacity(0.14)
        case .failure:
            return AppTheme.danger.opacity(0.12)
        case .capturing:
            return AppTheme.accent.opacity(0.14)
        case .preparing:
            return AppTheme.warning.opacity(0.14)
        case .neutral:
            return Color.white.opacity(0.66)
        }
    }

    private var isUnavailable: Bool {
        if case .unavailable = viewModel.sessionPhase {
            return true
        }
        return false
    }
}
