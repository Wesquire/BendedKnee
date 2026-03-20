import Foundation

struct AppLaunchConfiguration {
    let showsSplash: Bool
    let splashDurationNanoseconds: UInt64
    private let shouldPersistSplashCompletion: Bool
    private let defaults: UserDefaults?

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults = .standard
    ) {
        let uiTesting = arguments.contains("UITESTING")
        let forceSplashInUITests = arguments.contains("SHOW_SPLASH")
        let fastSplash = arguments.contains("FAST_SPLASH")

        if uiTesting && !forceSplashInUITests {
            self.showsSplash = false
            self.splashDurationNanoseconds = 0
            self.shouldPersistSplashCompletion = false
            self.defaults = nil
        } else if uiTesting {
            self.showsSplash = true
            self.splashDurationNanoseconds = fastSplash ? 2_000_000_000 : 2_500_000_000
            self.shouldPersistSplashCompletion = false
            self.defaults = nil
        } else {
            let hasShownSplash = defaults.bool(forKey: Keys.hasShownSplash)
            self.showsSplash = !hasShownSplash
            self.splashDurationNanoseconds = hasShownSplash ? 0 : 2_500_000_000
            self.shouldPersistSplashCompletion = !hasShownSplash
            self.defaults = defaults
        }
    }

    func recordSplashShownIfNeeded() {
        guard shouldPersistSplashCompletion else { return }
        defaults?.set(true, forKey: Keys.hasShownSplash)
    }

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
        recordSplashShownIfNeeded()
        return true
    }

    var hasPersistedFirstLaunchSplash: Bool {
        defaults?.bool(forKey: Keys.hasShownSplash) ?? false
    }

    static func resetPersistence(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: Keys.hasShownSplash)
    }
}

private extension AppLaunchConfiguration {
    enum Keys {
        static let hasShownSplash = "hasShownSplash"
    }
}
