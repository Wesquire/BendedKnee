import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if viewModel.showOnboarding {
                OnboardingView {
                    viewModel.dismissOnboarding()
                }
                .transition(.opacity)
            } else if viewModel.sessionPhase == .running || viewModel.sessionPhase == .pausedPocketRemoved {
                SessionView(viewModel: viewModel)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                HomeView(viewModel: viewModel)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.showOnboarding)
        .animation(.easeInOut(duration: 0.30), value: viewModel.sessionPhase == .running || viewModel.sessionPhase == .pausedPocketRemoved)
        .task {
            if scenePhase == .active && !viewModel.showOnboarding {
                viewModel.start()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && !viewModel.showOnboarding {
                viewModel.start()
                viewModel.handleAppReturnedToForeground()
            }
            if newPhase == .background {
                viewModel.handleAppMovedOutOfForeground()
            }
        }
        .onChange(of: viewModel.showOnboarding) { _, isShowingOnboarding in
            if !isShowingOnboarding && scenePhase == .active {
                viewModel.start()
            }
        }
    }
}
