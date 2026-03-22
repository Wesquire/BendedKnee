import SwiftUI

struct SettingsCard: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Fine-Tune Setup")
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            targetBendSection
            hapticsSection
            pulseAudioSection
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.panelSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 2)
                )
        )
        .shadow(color: AppTheme.deepInk.opacity(0.10), radius: 14, x: 0, y: 8)
    }

    private var targetBendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1. Target Bend")
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
    }

    private var hapticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2. Haptics")
                .font(AppType.label(13, weight: .bold))
                .foregroundStyle(AppTheme.inkMuted)

            Toggle(isOn: Binding(
                get: { viewModel.settings.hapticsEnabled },
                set: { viewModel.setHapticsEnabled($0) }
            )) {
                Text("Use vibration cues")
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
            }
            .tint(AppTheme.accent)
            .accessibilityIdentifier("hapticsToggle")

            Text("Turning this off disables calibration vibration, live session haptics, and slider ticks.")
                .font(AppType.label(12, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)
        }
    }

    private var pulseAudioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("3. Pulse Audio")
                .font(AppType.label(13, weight: .bold))
                .foregroundStyle(AppTheme.inkMuted)

            HStack {
                Image(systemName: "speaker.slash.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkMuted)
                Slider(
                    value: Binding(
                        get: { viewModel.settings.pulseVolume },
                        set: { viewModel.setPulseVolume($0) }
                    ),
                    in: AppSettings.volumeRange
                )
                .tint(AppTheme.accent)
                .accessibilityIdentifier("volumeSlider")
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkMuted)
            }

            Text("Volume: \(Int((viewModel.settings.pulseVolume * 100).rounded()))%")
                .font(AppType.label(12, weight: .semibold))
                .foregroundStyle(AppTheme.deepForest)

            Text("This controls the live session pulse audio and the calibration sounds. Move it to 0 for silent mode.")
                .font(AppType.label(12, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)

            Button(action: viewModel.playTestTone) {
                Label("Test Sound", systemImage: "speaker.wave.2.fill")
                    .font(AppType.label(14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.58))
                    .foregroundStyle(AppTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PrimaryFilledButtonStyle())
            .accessibilityIdentifier("testSoundButton")
        }
    }
}
