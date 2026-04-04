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
    @State private var iconScale: CGFloat = 0.82
    @State private var nameOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let iconSize = min(max(geometry.size.width * 0.32, 120), 170)
            let titleSize = min(max(geometry.size.width * 0.11, 36), 50)

            ZStack {
                PosterBackdrop(style: .warm).ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer()

                    DropIcon(size: iconSize)
                        .scaleEffect(iconScale)

                    Text(AppBrand.name)
                        .font(.system(size: titleSize, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundStyle(AppTheme.deepInk)
                        .opacity(nameOpacity)

                    Text(AppBrand.tagline)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.deepInk.opacity(0.65))
                        .opacity(nameOpacity)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.35)) {
                nameOpacity = 1.0
            }
        }
        .accessibilityIdentifier("splashView")
    }
}
