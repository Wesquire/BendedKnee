import SwiftUI

struct TuningDrawerView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var showPlacement = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    hapticsSection
                    audioSection
                    placementSection
                    samplePulseSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Tune")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Haptics

    private var hapticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HAPTICS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            Toggle(isOn: Binding(
                get: { viewModel.settings.hapticsEnabled },
                set: { viewModel.setHapticsEnabled($0) }
            )) {
                Text("Vibration coaching")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .tint(AppTheme.posterCoral)
            .accessibilityIdentifier("hapticsToggle")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    // MARK: - Audio

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PULSE AUDIO")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            HStack(spacing: 10) {
                Image(systemName: "speaker.slash.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { viewModel.settings.pulseVolume },
                        set: { viewModel.setPulseVolume($0) }
                    ),
                    in: AppSettings.volumeRange
                )
                .tint(AppTheme.posterCoral)
                .accessibilityIdentifier("volumeSlider")
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Text("Volume: \(Int((viewModel.settings.pulseVolume * 100).rounded()))%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Button(action: viewModel.playTestTone) {
                Label("Test Sound", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityIdentifier("testSoundButton")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    // MARK: - Placement Reference

    private var placementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showPlacement.toggle()
                }
            }) {
                HStack {
                    Text("PLACEMENT GUIDE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                    Spacer()
                    Image(systemName: showPlacement ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("skatingSetupDisclosure")

            if showPlacement {
                VStack(alignment: .leading, spacing: 8) {
                    Label(viewModel.settings.pocketSide.setupDescription, systemImage: "figure.walk")
                    Label("Phone top-up.", systemImage: "arrow.up")
                    Label(viewModel.settings.pocketSide.isFront ? "Screen facing your thigh." : "Screen facing away from you.", systemImage: "iphone")
                    Label("If the phone shifts, recalibrate.", systemImage: "arrow.triangle.2.circlepath")
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(UIColor.secondarySystemGroupedBackground)))
    }

    // MARK: - Sample Pulse

    private var samplePulseSection: some View {
        Button(action: viewModel.playHapticSample) {
            Label("Feel Sample Pulse", systemImage: "hand.tap.fill")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityIdentifier("samplePulseButton")
    }
}
