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
            } else if viewModel.sessionPhase == .running || viewModel.sessionPhase == .pausedPocketRemoved {
                SessionView(viewModel: viewModel)
            } else {
                HomeView(viewModel: viewModel)
            }
        }
        .task {
            if scenePhase == .active {
                viewModel.start()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.start()
            }
            if newPhase == .background {
                viewModel.handleAppMovedOutOfForeground()
            }
        }
    }
}
