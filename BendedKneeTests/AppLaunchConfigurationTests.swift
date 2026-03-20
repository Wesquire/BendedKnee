import XCTest
@testable import BendedKnee

final class AppLaunchConfigurationTests: XCTestCase {
    func testProductionLaunchShowsDefaultSplashDuration() {
        let configuration = AppLaunchConfiguration(arguments: [])

        XCTAssertTrue(configuration.showsSplash)
        XCTAssertEqual(configuration.splashDurationNanoseconds, 2_500_000_000)
    }

    func testUITestLaunchSkipsSplashByDefault() {
        let configuration = AppLaunchConfiguration(arguments: ["UITESTING"])

        XCTAssertFalse(configuration.showsSplash)
        XCTAssertEqual(configuration.splashDurationNanoseconds, 0)
    }

    func testUITestLaunchCanForceFastSplash() {
        let configuration = AppLaunchConfiguration(arguments: ["UITESTING", "SHOW_SPLASH", "FAST_SPLASH"])

        XCTAssertTrue(configuration.showsSplash)
        XCTAssertEqual(configuration.splashDurationNanoseconds, 150_000_000)
    }
}
