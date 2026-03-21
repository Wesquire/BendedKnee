import XCTest
@testable import BendedKnee

final class AppLaunchConfigurationTests: XCTestCase {
    func testProductionLaunchShowsDefaultSplashDuration() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let configuration = AppLaunchConfiguration(arguments: [], defaults: defaults)

        XCTAssertTrue(configuration.showsSplash)
        XCTAssertEqual(configuration.splashDurationNanoseconds, 2_500_000_000)
        XCTAssertFalse(configuration.hasPersistedFirstLaunchSplash)
    }

    func testProductionRepeatLaunchStillShowsSplash() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        _ = AppLaunchConfiguration(arguments: [], defaults: defaults)
        let secondLaunch = AppLaunchConfiguration(arguments: [], defaults: defaults)

        XCTAssertTrue(secondLaunch.showsSplash)
        XCTAssertEqual(secondLaunch.splashDurationNanoseconds, 2_500_000_000)
    }

    func testProductionLaunchDoesNotPersistSplashState() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let firstLaunch = AppLaunchConfiguration(arguments: [], defaults: defaults)
        firstLaunch.recordSplashShownIfNeeded()
        let secondLaunch = AppLaunchConfiguration(arguments: [], defaults: defaults)

        XCTAssertTrue(secondLaunch.showsSplash)
        XCTAssertEqual(secondLaunch.splashDurationNanoseconds, 2_500_000_000)
    }

    func testUITestLaunchSkipsSplashByDefault() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let configuration = AppLaunchConfiguration(arguments: ["UITESTING"], defaults: defaults)

        XCTAssertFalse(configuration.showsSplash)
        XCTAssertEqual(configuration.splashDurationNanoseconds, 0)
    }

    func testUITestLaunchCanForceFastSplash() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let configuration = AppLaunchConfiguration(arguments: ["UITESTING", "SHOW_SPLASH", "FAST_SPLASH"], defaults: defaults)

        XCTAssertTrue(configuration.showsSplash)
        XCTAssertEqual(configuration.splashDurationNanoseconds, 2_000_000_000)
    }

    func testCancelledSplashDelayDoesNotPersistCompletion() async {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let configuration = AppLaunchConfiguration(arguments: [], defaults: defaults)
        let task = Task {
            await configuration.completeSplashDelayIfNeeded { _ in
                try await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }

        task.cancel()
        let completed = await task.value

        XCTAssertFalse(completed)
        XCTAssertFalse(configuration.hasPersistedFirstLaunchSplash)
    }

    func testCompletedSplashDelayPersistsCompletion() async {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let configuration = AppLaunchConfiguration(arguments: [], defaults: defaults)
        let completed = await configuration.completeSplashDelayIfNeeded { _ in }

        XCTAssertTrue(completed)
        XCTAssertFalse(configuration.hasPersistedFirstLaunchSplash)
    }
}
