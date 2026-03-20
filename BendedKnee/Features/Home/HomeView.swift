import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        ZStack {
            AppTheme.homeBackground.ignoresSafeArea()

            Circle()
                .fill(AppTheme.accentSoft.opacity(0.18))
                .frame(width: 230, height: 230)
                .blur(radius: 14)
                .offset(x: 138, y: -286)

            Circle()
                .fill(AppTheme.mist.opacity(0.30))
                .frame(width: 200, height: 200)
                .blur(radius: 16)
                .offset(x: -132, y: 308)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroCard
                    calibrationCard
                    SettingsCard(viewModel: viewModel)
                }
                .padding(20)
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

            HStack(spacing: 14) {
                setupMetric(
                    title: "Pocket",
                    value: viewModel.settings.pocketSide.rawValue,
                    emphasis: AppTheme.deepForest
                )
                setupMetric(
                    title: "Target",
                    value: viewModel.targetAngleText,
                    emphasis: AppTheme.accent
                )
            }

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
                            .font(AppType.display(72))
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
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                Text("Standing baseline \(Int(baselineAngle.rounded()))°. The session view will coach you only when you rise too upright.")
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    setupStep(number: "1", title: "Pocket + target", detail: "\(viewModel.settings.pocketSide.rawValue) pocket, \(viewModel.targetAngleText) target")
                    setupStep(number: "2", title: "Calibrate upright", detail: "Stand still for the 3 second countdown")
                    setupStep(number: "3", title: "Start session", detail: "Skate with the app awake and the phone settled")
                }
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.deepForest.opacity(0.08), radius: 26, x: 0, y: 12)
    }

    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.setupStepTitle)
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            Text("This is the main setup step. Stand upright with the phone settled in your \(viewModel.settings.pocketSide.rawValue.lowercased()) front pocket, then stay still for the full countdown.")
                .font(AppType.label(15, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)

            Text("If the pocket moves too much, calibration will fail and you can try again immediately.")
                .font(AppType.label(13, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)

            if case .calibrating(let secondsRemaining) = viewModel.sessionPhase {
                HStack(spacing: 10) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Calibrating: \(secondsRemaining)")
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
            .disabled(viewModel.sessionPhase != .ready)
            .opacity(viewModel.sessionPhase == .ready ? 1 : 0.4)
            .accessibilityIdentifier("startSessionButton")
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
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

    private var isUnavailable: Bool {
        if case .unavailable = viewModel.sessionPhase {
            return true
        }
        return false
    }

    private func setupStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(AppType.label(14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(AppTheme.deepForest))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppType.label(14, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(detail)
                    .font(AppType.label(13, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            }
        }
    }

    private func setupMetric(title: String, value: String, emphasis: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppType.label(12, weight: .bold))
                .foregroundStyle(AppTheme.inkMuted)
            Text(value)
                .font(AppType.title(22))
                .foregroundStyle(emphasis)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
    }
}
