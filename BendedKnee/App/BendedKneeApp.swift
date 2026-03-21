import SwiftUI

@main
struct DropApp: App {
    @StateObject private var viewModel: SessionViewModel
    private let launchConfiguration: AppLaunchConfiguration

    init() {
        self.launchConfiguration = AppLaunchConfiguration()
        _viewModel = StateObject(wrappedValue: AppFactory.makeSessionViewModel())
    }

    var body: some Scene {
        WindowGroup {
            LaunchExperienceView(viewModel: viewModel, configuration: launchConfiguration)
        }
    }
}
