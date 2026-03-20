import SwiftUI

@main
struct BendedKneeApp: App {
    @StateObject private var viewModel: SessionViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AppFactory.makeSessionViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
        }
    }
}
