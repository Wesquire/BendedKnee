import Foundation

struct AppLaunchConfiguration {
    let showsSplash: Bool
    let splashDurationNanoseconds: UInt64

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let uiTesting = arguments.contains("UITESTING")
        let forceSplashInUITests = arguments.contains("SHOW_SPLASH")
        let fastSplash = arguments.contains("FAST_SPLASH")

        if uiTesting && !forceSplashInUITests {
            self.showsSplash = false
            self.splashDurationNanoseconds = 0
        } else {
            self.showsSplash = true
            self.splashDurationNanoseconds = fastSplash ? 150_000_000 : 2_500_000_000
        }
    }
}
