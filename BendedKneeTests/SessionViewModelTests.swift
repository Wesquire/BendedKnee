import CoreMotion
import Foundation
import XCTest
@testable import BendedKnee

@MainActor
final class SessionViewModelTests: XCTestCase {
    func testCalibrationProducesReadyState() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 1_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 4)
        motion.emit(angle: 5)
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 2_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        motion.emit(angle: 6)

        try? await Task.sleep(nanoseconds: 25_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertNotNil(viewModel.baselineAngle)
    }

    func testPocketRemovalPausesSessionAndStopsHaptics() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 1_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 5)
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 2_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 25_000_000)

        viewModel.startSession()
        motion.emit(angle: 2)
        proximity.emit(false)

        XCTAssertEqual(viewModel.sessionPhase, .pausedPocketRemoved)
        XCTAssertGreaterThan(haptics.stopCount, 0)
    }

    func testPocketReturnAutomaticallyResumesSession() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 1_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 5)
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 2_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 25_000_000)

        viewModel.startSession()
        motion.emit(angle: 2)
        proximity.emit(false)
        XCTAssertEqual(viewModel.sessionPhase, .pausedPocketRemoved)

        proximity.emit(true)

        XCTAssertEqual(viewModel.sessionPhase, .running)
        XCTAssertEqual(viewModel.statusText, HapticZone.zone(for: max(0, viewModel.settings.targetAngle - viewModel.currentAngle)).label)
    }

    func testCalibrationFailsWhenMovementIsTooNoisy() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 1_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 1,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 2_000_000)
        motion.emit(angle: 4)
        motion.emit(angle: 12)
        motion.emit(angle: 2)

        try? await Task.sleep(nanoseconds: 25_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .idle)
        XCTAssertNil(viewModel.baselineAngle)
        XCTAssertEqual(viewModel.statusText, "Calibration failed. Hold still and keep the phone settled.")
    }

    func testUnavailableMotionShowsUnavailableState() {
        let motion = MockMotionService()
        motion.isAvailable = false
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            defaults: defaults
        )

        viewModel.start()

        XCTAssertEqual(viewModel.sessionPhase, .unavailable("Motion data is unavailable on this device."))
        XCTAssertEqual(viewModel.statusText, "Motion data is unavailable.")
    }

    func testCalibrationDoesNotReuseStalePreCalibrationSamples() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 1_000_000,
            minimumCalibrationSamples: 2,
            maximumCalibrationSpreadDegrees: 1.5,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 25)
        motion.emit(angle: 28)

        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 2_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 25_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.baselineAngle.map { Int($0.rounded()) }, 5)
    }

    func testTargetAngleIsClampedToConfiguredRange() {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            defaults: defaults
        )

        viewModel.setTargetAngle(-4)
        XCTAssertEqual(viewModel.settings.targetAngle, AppSettings.targetRange.lowerBound)

        viewModel.setTargetAngle(90)
        XCTAssertEqual(viewModel.settings.targetAngle, AppSettings.targetRange.upperBound)
    }

    func testReopenOnboardingSetsPresentationFlag() {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        XCTAssertFalse(viewModel.showOnboarding)

        viewModel.reopenOnboarding()
        XCTAssertTrue(viewModel.showOnboarding)
    }
}

private final class MockMotionService: MotionServiceProtocol {
    var isAvailable: Bool = true
    private var handler: ((MotionSnapshot) -> Void)?

    func start(handler: @escaping (MotionSnapshot) -> Void) {
        self.handler = handler
    }

    func stop() {}

    func emit(angle: Double) {
        let radians = angle * .pi / 180
        let gravity = CMAcceleration(x: 0, y: -cos(radians), z: sin(radians))
        handler?(MotionSnapshot(gravity: gravity, timestamp: 0))
    }
}

private final class MockProximityService: ProximityMonitoring {
    var isSupported: Bool = true
    var currentState: Bool = true
    private var handler: ((Bool) -> Void)?

    func start(handler: @escaping (Bool) -> Void) {
        self.handler = handler
        handler(currentState)
    }

    func stop() {}

    func emit(_ isNear: Bool) {
        currentState = isNear
        handler?(isNear)
    }
}

private final class MockHapticsService: HapticsControlling {
    private(set) var stopCount = 0

    func start() {}
    func update(deficit: Double) {}

    func stopAll() {
        stopCount += 1
    }
}
