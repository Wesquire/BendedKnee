import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var showTuningDrawer = false

    private var zone: HapticZone {
        guard viewModel.baselineAngle != nil else { return .none }
        return HapticZone.zone(for: max(0, viewModel.settings.targetAngle - viewModel.currentAngle))
    }

    private var isCalibrating: Bool {
        if case .calibrating = viewModel.sessionPhase { return true }
        return false
    }

    private var calibrationSecondsRemaining: Int? {
        if case .calibrating(let s) = viewModel.sessionPhase { return s }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            let gaugeSize = min(geometry.size.width * 0.62, 280)
            let numberSize = min(geometry.size.width * 0.26, 100)

            ZStack {
                PosterBackdrop(style: .home).ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Top bar ──
                    HStack {
                        DropIcon(size: 32)
                        Text(AppBrand.name)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.deepInk)
                            .tracking(1.0)

                        Spacer()

                        Button(action: { showTuningDrawer = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppTheme.deepInk.opacity(0.55))
                        }
                        .accessibilityIdentifier("settingsGearButton")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 4)

                    Spacer(minLength: 4)

                    // ── Center: gauge or calibration countdown ──
                    if isCalibrating {
                        calibrationCountdown(gaugeSize: gaugeSize)
                    } else {
                        ArcGaugeView(
                            currentAngle: viewModel.currentAngle,
                            targetAngle: viewModel.settings.targetAngle,
                            zone: zone,
                            isPaused: false,
                            numberSize: numberSize,
                            arcDiameter: gaugeSize,
                            strokeWidth: 3.0,
                            showTargetLabel: false
                        )
                        .accessibilityIdentifier("homeArcGauge")
                    }

                    // Calibration feedback
                    if !isCalibrating {
                        calibrationStatusLabel
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 12)

                    // ── Controls: pocket + target ──
                    if !isCalibrating {
                        controlsSection
                            .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 16)

                    // ── Primary action ──
                    actionButton
                        .padding(.horizontal, 32)

                    // Error text
                    if case .unavailable(let message) = viewModel.sessionPhase {
                        Text(message)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.top, 6)
                    }

                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom + 16)
                }
            }
            .sheet(isPresented: $showTuningDrawer) {
                TuningDrawerView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Controls Section (Pocket + Target)

    private var controlsSection: some View {
        VStack(spacing: 14) {
            // Pocket selector
            VStack(spacing: 6) {
                Text("POCKET")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.deepInk.opacity(0.40))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(PocketSide.allCases) { pocket in
                        let isSelected = viewModel.settings.pocketSide == pocket && viewModel.pocketConfirmed
                        Button(action: { viewModel.setPocketSide(pocket) }) {
                            VStack(spacing: 2) {
                                Text(pocket.isFront ? "Front" : "Back")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                Text(pocket.rawValue.contains("Left") ? "Left" : "Right")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                            }
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? AppTheme.posterCoral : AppTheme.deepInk.opacity(0.06))
                            )
                            .foregroundStyle(isSelected ? .white : AppTheme.deepInk.opacity(0.65))
                        }
                        .accessibilityIdentifier("pocket_\(pocket.shortLabel)")
                    }
                }
            }

            // Target slider
            VStack(spacing: 4) {
                HStack {
                    Text("TARGET")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.deepInk.opacity(0.40))

                    Spacer()

                    Text(viewModel.targetAngleText)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.posterCoral)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { viewModel.settings.targetAngle },
                        set: { viewModel.setTargetAngle($0) }
                    ),
                    in: AppSettings.targetRange,
                    step: 1
                )
                .tint(AppTheme.posterCoral)
                .accessibilityIdentifier("targetSlider")
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Calibration Countdown

    @ViewBuilder
    private func calibrationCountdown(gaugeSize: CGFloat) -> some View {
        let seconds = calibrationSecondsRemaining ?? 0
        let isPreparing = viewModel.calibrationStage == .preparing

        ZStack {
            ArcShape(progress: 1.0)
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: gaugeSize, height: gaugeSize)

            ArcShape(progress: isPreparing ? 0.0 : 0.5)
                .stroke(
                    isPreparing ? AppTheme.posterGold : AppTheme.posterTeal,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: gaugeSize, height: gaugeSize)
                .shadow(color: (isPreparing ? AppTheme.posterGold : AppTheme.posterTeal).opacity(0.4), radius: 8)

            VStack(spacing: 8) {
                Text("\(seconds)")
                    .font(.system(size: gaugeSize * 0.35, weight: .black, design: .rounded))
                    .foregroundStyle(isPreparing ? AppTheme.posterGold : AppTheme.posterTeal)
                    .monospacedDigit()

                Text(isPreparing ? "POCKET THE PHONE" : "HOLD STILL")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.deepInk.opacity(0.60))
            }
        }
        .accessibilityIdentifier("calibrationCountdown")
    }

    // MARK: - Calibration Status Label

    @ViewBuilder
    private var calibrationStatusLabel: some View {
        switch viewModel.calibrationFeedbackStyle {
        case .success:
            Label("Baseline locked", systemImage: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.success)
        case .failure:
            Label("Try again — hold still in your pocket", systemImage: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.danger)
        case .neutral:
            if viewModel.baselineAngle != nil {
                EmptyView()
            } else if !viewModel.pocketConfirmed {
                Text("Pick a pocket, then calibrate")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.deepInk.opacity(0.45))
            } else {
                Text("Calibrate to begin")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.deepInk.opacity(0.45))
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if isCalibrating {
            EmptyView()
        } else if viewModel.canStartSession {
            // Ready to skate — two buttons: primary Skate + subtle Recalibrate
            VStack(spacing: 10) {
                Button(action: viewModel.startSession) {
                    Text("Skate")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppTheme.posterGold)
                                .shadow(color: AppTheme.posterGold.opacity(0.40), radius: 12, x: 0, y: 6)
                        )
                        .foregroundStyle(AppTheme.deepInk)
                }
                .accessibilityIdentifier("startSessionButton")

                Button(action: viewModel.beginCalibration) {
                    Text("Recalibrate")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.deepInk.opacity(0.45))
                }
                .accessibilityIdentifier("calibrateButton")
            }
        } else if viewModel.baselineAngle != nil {
            Button(action: viewModel.beginCalibration) {
                Text("Recalibrate")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.posterCoral)
                    )
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("calibrateButton")
        } else {
            Button(action: viewModel.beginCalibration) {
                Text("Calibrate")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1.0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(viewModel.pocketConfirmed ? AppTheme.posterCoral : AppTheme.deepInk.opacity(0.12))
                            .shadow(color: viewModel.pocketConfirmed ? AppTheme.posterCoral.opacity(0.35) : .clear, radius: 12, x: 0, y: 6)
                    )
                    .foregroundStyle(viewModel.pocketConfirmed ? .white : AppTheme.deepInk.opacity(0.30))
            }
            .disabled(!viewModel.pocketConfirmed || {
                if case .unavailable = viewModel.sessionPhase { return true }
                return false
            }())
            .accessibilityIdentifier("calibrateButton")
        }
    }
}
