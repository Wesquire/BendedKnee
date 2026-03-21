import SwiftUI

struct SettingsCard: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Fine-Tune Setup")
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            VStack(alignment: .leading, spacing: 10) {
                Text("1. Pocket Side")
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
                Text("2. Target Bend")
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

                Text("0° to 60° of extra bend beyond standing.")
                    .font(AppType.label(12, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            }

            supportToolsContent
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

    private var supportToolsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview Haptic")
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
        }
    }
}
