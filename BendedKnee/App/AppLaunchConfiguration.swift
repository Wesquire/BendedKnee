import Foundation

struct AppLaunchConfiguration {
    let showsSplash: Bool
    let splashDurationNanoseconds: UInt64

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults _: UserDefaults = .standard
    ) {
        let uiTesting = arguments.contains("UITESTING")
        let forceSplashInUITests = arguments.contains("SHOW_SPLASH")
        let fastSplash = arguments.contains("FAST_SPLASH")

        if uiTesting && !forceSplashInUITests {
            self.showsSplash = false
            self.splashDurationNanoseconds = 0
        } else if uiTesting {
            self.showsSplash = true
            self.splashDurationNanoseconds = fastSplash ? 2_000_000_000 : 2_500_000_000
        } else {
            self.showsSplash = true
            self.splashDurationNanoseconds = 2_500_000_000
        }
    }

    func recordSplashShownIfNeeded() {}

    func completeSplashDelayIfNeeded(
        sleeper: (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) async -> Bool {
        guard showsSplash else { return false }
        do {
            if splashDurationNanoseconds > 0 {
                try await sleeper(splashDurationNanoseconds)
            }
        } catch {
            return false
        }
        return true
    }

    var hasPersistedFirstLaunchSplash: Bool {
        false
    }

    static func resetPersistence(defaults _: UserDefaults = .standard) {}
}
