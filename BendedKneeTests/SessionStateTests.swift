import XCTest
@testable import BendedKnee

final class SessionStateTests: XCTestCase {

    // MARK: - SessionPhase Tests

    func testSessionPhase_idleEquality() {
        XCTAssertEqual(SessionPhase.idle, SessionPhase.idle)
    }

    func testSessionPhase_calibratingEquality() {
        XCTAssertEqual(
            SessionPhase.calibrating(secondsRemaining: 3),
            SessionPhase.calibrating(secondsRemaining: 3)
        )
    }

    func testSessionPhase_calibratingInequality() {
        XCTAssertNotEqual(
            SessionPhase.calibrating(secondsRemaining: 3),
            SessionPhase.calibrating(secondsRemaining: 2)
        )
    }

    func testSessionPhase_runningEquality() {
        XCTAssertEqual(SessionPhase.running, SessionPhase.running)
    }

    func testSessionPhase_pausedPocketRemovedEquality() {
        XCTAssertEqual(SessionPhase.pausedPocketRemoved, SessionPhase.pausedPocketRemoved)
    }

    func testSessionPhase_unavailableEquality() {
        XCTAssertEqual(
            SessionPhase.unavailable("test"),
            SessionPhase.unavailable("test")
        )
    }

    func testSessionPhase_differentPhasesNotEqual() {
        XCTAssertNotEqual(SessionPhase.idle, SessionPhase.running)
        XCTAssertNotEqual(SessionPhase.running, SessionPhase.pausedPocketRemoved)
        XCTAssertNotEqual(SessionPhase.idle, SessionPhase.ready)
    }

    func testSessionPhase_onboardingEquality() {
        XCTAssertEqual(SessionPhase.onboarding, SessionPhase.onboarding)
    }

    func testSessionPhase_readyEquality() {
        XCTAssertEqual(SessionPhase.ready, SessionPhase.ready)
    }

    // MARK: - AppSettings Tests

    func testAppSettings_defaultValues() {
        let settings = AppSettings()
        XCTAssertEqual(settings.targetAngle, 20)
    }

    func testAppSettings_targetRange() {
        XCTAssertEqual(AppSettings.targetRange.lowerBound, 0)
        XCTAssertEqual(AppSettings.targetRange.upperBound, 60)
    }

    func testAppSettings_equatable() {
        let a = AppSettings(targetAngle: 30)
        let b = AppSettings(targetAngle: 30)
        let c = AppSettings(targetAngle: 31)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - ExponentialSmoother Tests

    func testSmoother_firstValuePassthrough() {
        var smoother = ExponentialSmoother()
        let result = smoother.add(10)
        XCTAssertEqual(result, 10, accuracy: 0.001)
    }

    func testSmoother_subsequentValuesSmoothed() {
        var smoother = ExponentialSmoother(alpha: 0.5)
        _ = smoother.add(10)
        let result = smoother.add(20)
        // value = 10 + 0.5 * (20 - 10) = 15
        XCTAssertEqual(result, 15, accuracy: 0.001)
    }

    func testSmoother_reset() {
        var smoother = ExponentialSmoother()
        _ = smoother.add(10)
        smoother.reset()
        XCTAssertNil(smoother.value)
        let result = smoother.add(50)
        XCTAssertEqual(result, 50, accuracy: 0.001)
    }

    // MARK: - Integration: Deficit + Zone Pipeline

    func testDeficitToZone_pipeline() {
        // target = 20, current = 10 -> deficit = 10 -> medium zone
        let deficit = max(0, 20.0 - 10.0)
        let zone = HapticZone.zone(for: deficit)
        XCTAssertEqual(zone, .medium)
    }

    func testDeficitToZone_onTarget() {
        let deficit = max(0, 20.0 - 20.0)
        let zone = HapticZone.zone(for: deficit)
        XCTAssertEqual(zone, .none)
    }

    func testDeficitToZone_exceeding() {
        let deficit = max(0, 20.0 - 30.0)
        let zone = HapticZone.zone(for: deficit)
        XCTAssertEqual(zone, .none)
    }

    func testDeficitToZone_slightlyShort() {
        let deficit = max(0, 20.0 - 17.0)
        let zone = HapticZone.zone(for: deficit)
        XCTAssertEqual(zone, .gentle)
    }

    func testDeficitToZone_veryShort() {
        let deficit = max(0, 30.0 - 0.0)
        let zone = HapticZone.zone(for: deficit)
        XCTAssertEqual(zone, .strong)
    }
}
