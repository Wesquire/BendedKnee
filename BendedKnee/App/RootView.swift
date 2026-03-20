import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: SessionViewModel

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
            viewModel.start()
        }
    }
}
