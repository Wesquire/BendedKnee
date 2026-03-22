import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var showingSetupInstructions = true

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width - 22, 560)

            ZStack {
                PosterBackdrop(style: .home).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        heroCard
                        instructionsCard
                        calibrationCard
                        SettingsCard(viewModel: viewModel)
                    }
                    .frame(maxWidth: contentWidth)
                    .padding(.horizontal, 11)
                    .padding(.top, max(geometry.safeAreaInsets.top, 10) + 6)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16) + 12)
                    .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                showingSetupInstructions = viewModel.baselineAngle == nil
            }
            .onChange(of: viewModel.baselineAngle) { _, newBaseline in
                if newBaseline != nil {
                    showingSetupInstructions = false
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.setupSummaryTitle.uppercased())
                .font(AppType.label(12, weight: .bold))
                .foregroundStyle(AppTheme.deepInk.opacity(0.72))
                .tracking(1.6)

            Text(viewModel.setupSummaryDetail)
                .font(AppType.label(16, weight: .bold))
                .foregroundStyle(AppTheme.ink)

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
                            .font(AppType.display(60))
                            .minimumScaleFactor(0.52)
                            .foregroundStyle(AppTheme.deepInk)
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
                            .foregroundStyle(AppTheme.posterCoral)
                    }
                }

                Text("Standing baseline \(Int(baselineAngle.rounded()))°. Drop coaches you when you rise too upright.")
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            } else {
                Text("Fine-tune your target, haptics, and audio below, then run a 7-second upright calibration before you skate.")
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
        .background(cardBackground(cornerRadius: 26))
        .shadow(color: AppTheme.deepInk.opacity(0.14), radius: 20, x: 0, y: 10)
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                    showingSetupInstructions.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set-Up Instructions")
                            .font(AppType.title(22))
                            .foregroundStyle(AppTheme.ink)

                        Text("Placement and calibration guidance for every session.")
                            .font(AppType.label(13, weight: .semibold))
                            .foregroundStyle(AppTheme.inkMuted)
                    }

                    Spacer()

                    Image(systemName: showingSetupInstructions ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.posterCoral)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("skatingSetupDisclosure")

            if showingSetupInstructions {
                VStack(alignment: .leading, spacing: 14) {
                    instructionSection(
                        title: "Calibration",
                        rows: [
                            ("timer", "Tap calibrate, then put the phone in your left front pocket right away."),
                            ("waveform.path.ecg", "Stand upright and stay still during the 7-second calibration."),
                            ("speaker.wave.2.fill", "You will hear a confirmation sound and feel vibration when calibration finishes."),
                            ("list.number", "Set target bend, adjust haptics and audio, calibrate upright, then start your session.")
                        ]
                    )

                    Divider()
                        .overlay(AppTheme.line)

                    instructionSection(
                        title: "Placement",
                        rows: [
                            ("figure.walk", "Use your left front pocket every time."),
                            ("arrow.up", "Keep the phone top-up."),
                            ("iphone", "Keep the screen facing your thigh."),
                            ("lock.open", "Keep the app open and in the foreground while skating.")
                        ]
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(cardBackground(cornerRadius: 24, fill: AppTheme.panelSecondary))
        .shadow(color: AppTheme.deepInk.opacity(0.10), radius: 16, x: 0, y: 8)
    }

    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.setupStepTitle)
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            Text("Tap calibrate, place the phone in your left front pocket, then stand upright and still. Calibration takes 7 seconds total, and you will hear a confirmation sound and feel vibration when it completes.")
                .font(AppType.label(15, weight: .medium))
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

                if !viewModel.calibrationBannerDetail.isEmpty {
                    Text(viewModel.calibrationBannerDetail)
                        .font(AppType.label(13, weight: .medium))
                        .foregroundStyle(AppTheme.inkMuted)
                }
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
                .foregroundStyle(AppTheme.posterCoral)
            }

            Button(action: viewModel.beginCalibration) {
                Text(viewModel.baselineAngle == nil ? "Calibrate Standing Position" : "Recalibrate Standing Position")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.posterCoral)
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
                    .background(AppTheme.deepInk)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PrimaryFilledButtonStyle())
            .disabled(!viewModel.canStartSession)
            .opacity(viewModel.canStartSession ? 1 : 0.4)
            .accessibilityIdentifier("startSessionButton")
        }
        .padding(18)
        .background(cardBackground(cornerRadius: 24, fill: AppTheme.panelSecondary))
        .shadow(color: AppTheme.deepInk.opacity(0.10), radius: 16, x: 0, y: 8)
    }

    private func instructionSection(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppType.label(13, weight: .bold))
                .foregroundStyle(AppTheme.inkMuted)

            ForEach(rows, id: \.1) { row in
                Label(row.1, systemImage: row.0)
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
            }
        }
    }

    private func cardBackground(cornerRadius: CGFloat, fill: Color = AppTheme.panel) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.76), lineWidth: 2)
            )
    }

    private var statusColor: Color {
        switch HapticZone.zone(for: max(0, viewModel.settings.targetAngle - viewModel.currentAngle)) {
        case .none:
            return AppTheme.success
        case .gentle:
            return AppTheme.warning
        case .medium:
            return AppTheme.posterTeal
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
            return AppTheme.posterTeal.opacity(0.16)
        case .preparing:
            return AppTheme.warning.opacity(0.16)
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
