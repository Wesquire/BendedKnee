import SwiftUI

struct SettingsCard: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Setup")
                .font(AppType.title(24))
                .foregroundStyle(AppTheme.ink)

            Text("Set how many extra degrees of bend you want beyond standing upright, then review the placement rules before you calibrate.")
                .font(AppType.label(14, weight: .medium))
                .foregroundStyle(AppTheme.inkMuted)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Target Bend")
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

                Text("0° to 60° in 1° steps. This is extra bend compared with your calibrated upright stance.")
                    .font(AppType.label(12, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)

                Text("Example: if standing tilt is 6° and you choose 20°, the coaching threshold is about 26° live tilt.")
                    .font(AppType.label(12, weight: .medium))
                    .foregroundStyle(AppTheme.inkMuted)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Placement Rules")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)

                Label("Use the same front pocket every session.", systemImage: "figure.walk")
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
                    .background(Color.white.opacity(0.58))
                    .foregroundStyle(AppTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
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
