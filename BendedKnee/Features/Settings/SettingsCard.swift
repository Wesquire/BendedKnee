import SwiftUI

struct SettingsCard: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Fine-Tune Setup")
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            pocketSideSection
            targetBendSection
            pulseVolumeSection
            previewSection
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.panelSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.deepForest.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    // MARK: - Pocket Side

    private var pocketSideSection: some View {
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
    }

    // MARK: - Target Bend

    private var targetBendSection: some View {
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
    }

    // MARK: - Pulse Volume

    private var pulseVolumeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("3. Pulse Audio")
                .font(AppType.label(13, weight: .bold))
                .foregroundStyle(AppTheme.inkMuted)

            Toggle(isOn: Binding(
                get: { viewModel.settings.pulseAudioEnabled },
                set: { viewModel.setPulseAudioEnabled($0) }
            )) {
                Text("Sound pulses during session")
                    .font(AppType.label(14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
            }
            .tint(AppTheme.accent)
            .accessibilityIdentifier("pulseAudioToggle")

            if viewModel.settings.pulseAudioEnabled {
                HStack {
                    Image(systemName: "speaker.fill")
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

                Button(action: viewModel.playTestTone) {
                    Label("Test Sound", systemImage: "speaker.wave.2")
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

    // MARK: - Preview Haptic

    private var previewSection: some View {
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
