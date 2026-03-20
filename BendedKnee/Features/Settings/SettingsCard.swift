import SwiftUI

struct SettingsCard: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("1. Choose Pocket")
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            Text("Pick the pocket you will actually skate with. Keep the phone top-up with the screen toward your thigh.")
                .font(AppType.label(14, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)

            VStack(alignment: .leading, spacing: 10) {
                Text("Pocket Side")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)

                Picker("Pocket Side", selection: Binding(
                    get: { viewModel.settings.pocketSide },
                    set: { viewModel.setPocketSide($0) }
                )) {
                    ForEach(PocketSide.allCases) { side in
                        Text(side.rawValue).tag(side)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("pocketSidePicker")

                Text(viewModel.settings.pocketSide.setupDescription)
                    .font(AppType.label(12, weight: .semibold))
                    .foregroundStyle(AppTheme.deepForest)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("2. Set Target Bend")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)

                HStack {
                    Text("Target")
                        .font(AppType.label(13, weight: .bold))
                        .foregroundStyle(AppTheme.inkMuted)
                    Spacer()
                    Text(viewModel.targetAngleText)
                        .font(AppType.display(20))
                        .foregroundStyle(AppTheme.deepForest)
                }

                Slider(
                    value: Binding(
                        get: { viewModel.settings.targetAngle },
                        set: { viewModel.setTargetAngle($0) }
                    ),
                    in: AppSettings.targetRange,
                    step: 1
                )
                .tint(AppTheme.accent)
                .accessibilityIdentifier("targetSlider")

                Text("0° to 60° in 1° steps. This is how much extra bend you want beyond standing.")
                    .font(AppType.label(12, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)

                Text(viewModel.setupTargetExampleText)
                    .font(AppType.label(12, weight: .semibold))
                    .foregroundStyle(AppTheme.deepForest)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Haptic Preview")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)

                Button(action: viewModel.playHapticSample) {
                    Text("Feel Sample Pulse")
                        .font(AppType.label(15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.58))
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PrimaryFilledButtonStyle())
                .accessibilityIdentifier("samplePulseButton")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Placement Rules")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)

                Label("Keep the phone in your selected front pocket.", systemImage: "figure.walk")
                Label("Keep the phone top-up.", systemImage: "arrow.up")
                Label("Keep the screen facing your thigh.", systemImage: "iphone")
            }
            .font(AppType.label(14, weight: .medium))
            .foregroundStyle(AppTheme.ink)

            Button(action: viewModel.reopenOnboarding) {
                Text("Review Setup Guide")
                    .font(AppType.label(15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.82))
                    .foregroundStyle(AppTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .accessibilityIdentifier("reopenOnboardingButton")
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
}
