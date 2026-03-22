import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if viewModel.showOnboarding {
                OnboardingView {
                    viewModel.dismissOnboarding()
                }
            } else if viewModel.showWelcomeBack {
                WelcomeBackView(dismiss: viewModel.dismissWelcomeBack)
            } else if viewModel.sessionPhase == .running || viewModel.sessionPhase == .pausedPocketRemoved {
                SessionView(viewModel: viewModel)
            } else {
                HomeView(viewModel: viewModel)
            }
        }
        .task {
            if scenePhase == .active && !viewModel.showOnboarding && !viewModel.showWelcomeBack {
                viewModel.start()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && !viewModel.showOnboarding && !viewModel.showWelcomeBack {
                viewModel.start()
            }
            if newPhase == .background {
                viewModel.handleAppMovedOutOfForeground()
            }
        }
        .onChange(of: viewModel.showOnboarding) { _, isShowingOnboarding in
            if !isShowingOnboarding && !viewModel.showWelcomeBack && scenePhase == .active {
                viewModel.start()
            }
        }
        .onChange(of: viewModel.showWelcomeBack) { _, isShowingWelcomeBack in
            if !isShowingWelcomeBack && !viewModel.showOnboarding && scenePhase == .active {
                viewModel.start()
            }
        }
    }
}
