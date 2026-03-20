import SwiftUI

struct LaunchExperienceView: View {
    @ObservedObject var viewModel: SessionViewModel
    let configuration: AppLaunchConfiguration

    @State private var showingSplash: Bool

    init(viewModel: SessionViewModel, configuration: AppLaunchConfiguration) {
        self.viewModel = viewModel
        self.configuration = configuration
        _showingSplash = State(initialValue: configuration.showsSplash)
    }

    var body: some View {
        Group {
            if showingSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                RootView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .task(id: showingSplash) {
            guard showingSplash else { return }
            if configuration.splashDurationNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: configuration.splashDurationNanoseconds)
            }
            withAnimation(.easeOut(duration: 0.35)) {
                showingSplash = false
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.paper,
                    AppTheme.sand,
                    AppTheme.mist.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppTheme.accentSoft.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 18)
                .offset(x: 120, y: -260)

            Circle()
                .fill(AppTheme.mist.opacity(0.30))
                .frame(width: 260, height: 260)
                .blur(radius: 24)
                .offset(x: -140, y: 280)

            VStack(spacing: 28) {
                Spacer()

                BendedKneeBrandMark(
                    iconSize: 136,
                    titleSize: 42,
                    subtitle: "Skate lower. Feel it sooner."
                )

                Text("Pocket coach for deeper knee bend")
                    .font(AppType.label(16, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)

                Spacer()

                Text("Loading setup...")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted.opacity(0.84))
                    .padding(.bottom, 26)
            }
            .padding(.horizontal, 28)
        }
        .accessibilityIdentifier("splashView")
    }
}
