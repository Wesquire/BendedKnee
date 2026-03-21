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
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                    .blur(radius: 18)
                    .offset(x: geometry.size.width * 0.28, y: -geometry.size.height * 0.28)

                Circle()
                    .fill(AppTheme.mist.opacity(0.30))
                    .frame(width: geometry.size.width * 0.62, height: geometry.size.width * 0.62)
                    .blur(radius: 24)
                    .offset(x: -geometry.size.width * 0.34, y: geometry.size.height * 0.30)

                VStack(spacing: max(20, geometry.size.height * 0.026)) {
                    Spacer()

                    DropBrandMark(
                        iconSize: brandIconSize,
                        titleSize: titleSize,
                        subtitle: AppBrand.tagline
                    )

                    Text("Pocket coach for deeper knee bend")
                        .font(AppType.label(16, weight: .bold))
                        .foregroundStyle(AppTheme.inkMuted)
                        .accessibilityIdentifier("splashTagline")

                    Text("Set your pocket. Lock your baseline. Keep the app open while you skate.")
                        .font(AppType.label(13, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.inkMuted.opacity(0.88))
                        .frame(maxWidth: contentWidth - 24)

                    Spacer()
                }
                .frame(maxWidth: contentWidth)
                .padding(.horizontal, 16)
                .padding(.top, geometry.safeAreaInsets.top + 8)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityIdentifier("splashView")
    }
}
