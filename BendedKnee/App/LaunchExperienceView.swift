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
            guard await configuration.completeSplashDelayIfNeeded() else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                showingSplash = false
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width - 32, 460)
            let brandIconSize = min(max(geometry.size.width * 0.28, 110), 154)
            let titleSize = min(max(geometry.size.width * 0.10, 32), 48)

            ZStack {
                PosterBackdrop(style: .warm).ignoresSafeArea()

                VStack(spacing: max(20, geometry.size.height * 0.026)) {
                    Spacer()

                    DropBrandMark(
                        iconSize: brandIconSize,
                        titleSize: titleSize,
                        subtitle: AppBrand.tagline
                    )

                    Text("Pocket coach for deeper knee bend")
                        .font(AppType.posterTitle(18))
                        .foregroundStyle(AppTheme.deepInk)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("splashTagline")

                    Text("Left pocket. Big posture coaching. Vibrations and pulse audio that hit faster.")
                        .font(AppType.label(13, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.deepInk.opacity(0.84))
                        .frame(maxWidth: contentWidth - 24)

                    Spacer()
                }
                .frame(maxWidth: contentWidth)
                .padding(.horizontal, 16)
                .padding(.top, geometry.safeAreaInsets.top + 12)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityIdentifier("splashView")
    }
}
