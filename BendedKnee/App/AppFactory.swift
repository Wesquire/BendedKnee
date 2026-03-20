import Foundation

enum AppFactory {
    @MainActor
    static func makeSessionViewModel() -> SessionViewModel {
        let arguments = ProcessInfo.processInfo.arguments
        let uiTesting = arguments.contains("UITESTING")
        let fastCalibration = arguments.contains("FAST_CALIBRATION")
        let noisyCalibration = arguments.contains("NOISY_CALIBRATION")
        let motionService: MotionServiceProtocol = {
            guard uiTesting else { return DeviceMotionService() }
            if arguments.contains("UNAVAILABLE_MOTION") {
                return PreviewMotionService(mode: .unavailable)
            }
            if noisyCalibration {
                return PreviewMotionService(mode: .noisyCalibration)
            }
            return PreviewMotionService(mode: .steadySkate)
        }()
        let proximityService: ProximityMonitoring = {
            guard uiTesting else { return ProximityService() }
            if arguments.contains("AUTO_REMOVE_PROXIMITY") {
                return PreviewProximityService(mode: .autoRemove(after: 0.6))
            }
            return PreviewProximityService(mode: .steadyNear)
        }()
        let hapticsService: HapticsControlling = uiTesting ? NoOpHapticsService() : HapticsService()
        let defaults: UserDefaults = {
            guard uiTesting else { return .standard }
            let suiteName = "BendedKneeUITests"
            let defaults = UserDefaults(suiteName: suiteName) ?? .standard
            defaults.removePersistentDomain(forName: suiteName)
            return defaults
        }()
        return SessionViewModel(
            motionService: motionService,
            proximityService: proximityService,
            hapticsService: hapticsService,
            calibrationTickNanoseconds: noisyCalibration ? 200_000_000 : (fastCalibration ? 50_000_000 : 1_000_000_000),
            minimumCalibrationSamples: noisyCalibration ? 3 : (fastCalibration ? 1 : 8),
            maximumCalibrationSpreadDegrees: noisyCalibration ? 1 : (fastCalibration ? 5 : 2.25),
            testingAutoPauseAfterNanoseconds: arguments.contains("AUTO_REMOVE_PROXIMITY") ? 800_000_000 : nil,
            defaults: defaults
        )
    }
}
