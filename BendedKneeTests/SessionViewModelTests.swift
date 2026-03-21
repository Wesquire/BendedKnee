import CoreMotion
import Foundation
import SwiftUI
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
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(
            viewModel: viewModel,
            motion: motion,
            prepDelayNanoseconds: 20_000_000,
            settleDelayNanoseconds: 80_000_000,
            angles: [5, 5, 6]
        )

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
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(
            viewModel: viewModel,
            motion: motion,
            prepDelayNanoseconds: 20_000_000,
            settleDelayNanoseconds: 80_000_000
        )

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
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(
            viewModel: viewModel,
            motion: motion,
            prepDelayNanoseconds: 20_000_000,
            settleDelayNanoseconds: 80_000_000
        )

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
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 1,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 4)
        motion.emit(angle: 12)
        motion.emit(angle: 2)

        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .idle)
        XCTAssertNil(viewModel.baselineAngle)
        XCTAssertEqual(viewModel.statusText, "Calibration failed. Hold still, keep the phone settled, and try again.")
        XCTAssertEqual(haptics.calibrationFailureCueCount, 1)
    }

    func testCalibrationFailsWhenTooFewSamplesAreCollected() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 4,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .idle)
        XCTAssertNil(viewModel.baselineAngle)
        XCTAssertEqual(viewModel.statusText, "Calibration failed. Put the phone in your front pocket, let it settle, and try again.")
        XCTAssertEqual(haptics.calibrationFailureCueCount, 1)
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
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 2,
            maximumCalibrationSpreadDegrees: 1.5,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 25)
        motion.emit(angle: 28)

        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 20_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 80_000_000)

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

    func testPocketSidePersistsAndUpdatesGuidance() {
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
        viewModel.setPocketSide(.left)

        XCTAssertEqual(viewModel.settings.pocketSide, .left)
        XCTAssertEqual(defaults.string(forKey: "pocketSide"), PocketSide.left.rawValue)
        XCTAssertTrue(viewModel.guidanceText.contains("left front pocket"))
    }

    func testChangingPocketSideKeepsPlacementInvalidUntilRevalidated() {
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
        viewModel.start()
        motion.emit(gravity: CMAcceleration(x: 0, y: 0.9, z: 0.1))
        XCTAssertTrue(viewModel.placementInvalid)

        viewModel.setPocketSide(.left)

        XCTAssertTrue(viewModel.placementInvalid)
        XCTAssertEqual(viewModel.statusText, "Stand still to calibrate.")
    }

    func testStartSessionBecomesUnavailableWhenPlacementIsInvalid() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(viewModel: viewModel, motion: motion)

        XCTAssertTrue(viewModel.canStartSession)

        motion.emit(gravity: CMAcceleration(x: 0, y: 0.9, z: 0.1))

        XCTAssertTrue(viewModel.placementInvalid)
        XCTAssertFalse(viewModel.canStartSession)
        XCTAssertTrue(viewModel.startSessionHelperText.contains("Fix phone placement before starting"))
    }

    func testPreviewProximityServiceResetsStateAcrossStarts() {
        let proximity = PreviewProximityService(mode: .autoRemove(after: 10))
        var firstRunStates: [Bool] = []
        proximity.start { firstRunStates.append($0) }
        proximity.stop()

        var secondRunStates: [Bool] = []
        proximity.start { secondRunStates.append($0) }

        XCTAssertEqual(firstRunStates.first, true)
        XCTAssertEqual(secondRunStates.first, true)
        XCTAssertTrue(proximity.currentState)
    }

    func testRunningSessionExposesReadablePrimaryState() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(viewModel: viewModel, motion: motion)

        viewModel.startSession()
        motion.emit(angle: 8)

        XCTAssertEqual(viewModel.primarySessionTitle, "Below Target")
        XCTAssertEqual(viewModel.sessionBadgeText, "Below Target")
    }

    func testPausedPocketRemovalExposesReadablePrimaryState() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(viewModel: viewModel, motion: motion)

        viewModel.startSession()
        proximity.emit(false)

        XCTAssertEqual(viewModel.primarySessionTitle, "Phone Removed")
        XCTAssertEqual(viewModel.sessionBadgeText, "Phone Removed")
        XCTAssertTrue(viewModel.primarySessionDetail.contains("resume automatically"))
    }

    func testStartSessionImmediatelyPausesWhenPhoneIsAlreadyOutOfPocket() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        proximity.currentState = false
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 5)
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 50_000_000)

        viewModel.startSession()

        XCTAssertEqual(viewModel.sessionPhase, .pausedPocketRemoved)
        XCTAssertEqual(viewModel.statusText, "Phone removed. Haptics paused.")
    }

    func testDismissOnboardingPersistsAcrossViewModels() {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let suiteName = #function
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstViewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            defaults: defaults
        )

        XCTAssertTrue(firstViewModel.showOnboarding)
        firstViewModel.dismissOnboarding()

        let secondViewModel = SessionViewModel(
            motionService: MockMotionService(),
            proximityService: MockProximityService(),
            hapticsService: MockHapticsService(),
            defaults: defaults
        )

        XCTAssertFalse(secondViewModel.showOnboarding)
    }

    func testPlayHapticSampleTriggersPreviewPulse() {
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

        viewModel.playHapticSample()

        XCTAssertEqual(haptics.samplePulseCount, 1)
        XCTAssertEqual(viewModel.statusText, "Sample pulse sent. If you do not feel it, make sure you are testing on a real iPhone.")
    }

    func testPocketSideSettingPersistsAcrossViewModels() {
        let suiteName = #function
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstViewModel = SessionViewModel(
            motionService: MockMotionService(),
            proximityService: MockProximityService(),
            hapticsService: MockHapticsService(),
            defaults: defaults
        )
        firstViewModel.setPocketSide(.left)

        let secondViewModel = SessionViewModel(
            motionService: MockMotionService(),
            proximityService: MockProximityService(),
            hapticsService: MockHapticsService(),
            defaults: defaults
        )

        XCTAssertEqual(secondViewModel.settings.pocketSide, .left)
    }

    func testChangingPocketSideAllowsMirroredPlacementToValidate() {
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
        viewModel.start()
        motion.emit(gravity: CMAcceleration(x: -0.97, y: -0.15, z: 0.12))
        XCTAssertTrue(viewModel.placementInvalid)

        viewModel.setPocketSide(.left)
        motion.emit(gravity: CMAcceleration(x: -0.20, y: -0.95, z: 0.12))

        XCTAssertFalse(viewModel.placementInvalid)
    }

    func testStopSessionReturnsReadyStateAfterRunningSession() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(viewModel: viewModel, motion: motion)

        viewModel.startSession()
        XCTAssertEqual(viewModel.sessionPhase, .running)

        viewModel.stopSession()

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.statusText, "Session stopped.")
    }

    func testTestingAutoPauseTransitionsRunningSessionToPausedPocketRemoved() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            testingAutoPauseAfterNanoseconds: 1_000_000,
            defaults: defaults
        )

        await establishReadyState(viewModel: viewModel, motion: motion)

        viewModel.startSession()
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .pausedPocketRemoved)
        XCTAssertEqual(viewModel.statusText, "Phone removed. Haptics paused.")
        XCTAssertGreaterThan(haptics.stopCount, 0)
    }

    func testFailedRecalibrationKeepsPreviousBaseline() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(
            viewModel: viewModel,
            motion: motion,
            prepDelayNanoseconds: 20_000_000,
            settleDelayNanoseconds: 80_000_000
        )
        let originalBaseline = viewModel.baselineAngle
        XCTAssertNotNil(originalBaseline)

        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 20_000_000)
        motion.emit(angle: 2)
        motion.emit(angle: 12)
        motion.emit(angle: 20)
        try? await Task.sleep(nanoseconds: 60_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.baselineAngle, originalBaseline)
        XCTAssertEqual(viewModel.statusText, "Calibration failed. Hold still, keep the phone settled, and try again.")
        XCTAssertEqual(haptics.calibrationFailureCueCount, 1)
    }

    func testStartSessionIsBlockedWhileCalibrationIsRunning() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 5)
        viewModel.beginCalibration()

        viewModel.startSession()

        XCTAssertEqual(viewModel.sessionPhase, .calibrating(secondsRemaining: 1))
        XCTAssertEqual(viewModel.statusText, "Finish calibration before starting.")
    }

    func testBackgroundTransitionStopsRunningSession() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(
            viewModel: viewModel,
            motion: motion,
            prepDelayNanoseconds: 20_000_000,
            settleDelayNanoseconds: 80_000_000
        )

        viewModel.startSession()
        XCTAssertEqual(viewModel.sessionPhase, .running)

        viewModel.handleAppMovedOutOfForeground()

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.statusText, "Session paused because the app left the foreground.")
    }

    func testBackgroundTransitionCancelsCalibrationAndRestoresPreviousBaseline() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(
            viewModel: viewModel,
            motion: motion,
            prepDelayNanoseconds: 20_000_000,
            settleDelayNanoseconds: 80_000_000
        )
        let originalBaseline = viewModel.baselineAngle

        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 12)
        viewModel.handleAppMovedOutOfForeground()
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.baselineAngle, originalBaseline)
        XCTAssertEqual(viewModel.statusText, "Calibration paused because the app left the foreground.")
    }

    func testSecondCalibrationCancelsFirstTaskWithoutRestoringStaleResult() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 2,
            maximumCalibrationSpreadDegrees: 1,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()

        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)

        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 12)
        motion.emit(angle: 12)
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.baselineAngle.map { Int($0.rounded()) }, 12)
    }

    func testInvalidPlacementPreventsSessionStart() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(viewModel: viewModel, motion: motion)
        motion.emit(gravity: CMAcceleration(x: 0, y: 0.9, z: 0.1))

        viewModel.startSession()

        XCTAssertTrue(viewModel.placementInvalid)
        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.statusText, "Phone orientation invalid. Reinsert it top-up with the screen toward your thigh.")
    }

    func testInvalidPlacementStopsCoachingDuringRunningSession() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        motion.emit(angle: 5)
        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 50_000_000)
        viewModel.startSession()

        motion.emit(gravity: CMAcceleration(x: 0, y: -0.86, z: -0.3))

        XCTAssertTrue(viewModel.placementInvalid)
        XCTAssertEqual(viewModel.currentAngle, 0, accuracy: 0.001)
        XCTAssertEqual(viewModel.statusText, "Phone orientation invalid. Reinsert it top-up with the screen toward your thigh.")
        XCTAssertGreaterThan(haptics.stopCount, 0)
    }

    func testStopSessionDuringRecalibrationRestoresPreviousBaseline() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 3,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        await establishReadyState(viewModel: viewModel, motion: motion)
        let originalBaseline = viewModel.baselineAngle

        viewModel.beginCalibration()
        try? await Task.sleep(nanoseconds: 12_000_000)
        motion.emit(angle: 12)

        viewModel.stopSession()
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(viewModel.sessionPhase, .ready)
        XCTAssertEqual(viewModel.baselineAngle, originalBaseline)
        XCTAssertEqual(viewModel.statusText, "Session stopped.")
    }

    func testCalibrationStartsWithPrepStageThenSignalsSuccess() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationPrepSeconds: 1,
            calibrationCaptureSeconds: 2,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 1,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        viewModel.beginCalibration()

        XCTAssertEqual(viewModel.calibrationStage, .preparing)
        XCTAssertEqual(viewModel.sessionPhase, .calibrating(secondsRemaining: 1))

        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 20_000_000)
        motion.emit(angle: 5)
        try? await Task.sleep(nanoseconds: 30_000_000)

        XCTAssertEqual(haptics.calibrationStartCueCount, 1)
        XCTAssertEqual(haptics.calibrationSuccessCueCount, 1)
        XCTAssertEqual(viewModel.calibrationFeedbackStyle, .success)
        XCTAssertEqual(viewModel.sessionPhase, .ready)
    }

    func testCalibrationPlacementFailureUsesFailureCue() async {
        let motion = MockMotionService()
        let proximity = MockProximityService()
        let haptics = MockHapticsService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let viewModel = SessionViewModel(
            motionService: motion,
            proximityService: proximity,
            hapticsService: haptics,
            calibrationPrepSeconds: 1,
            calibrationCaptureSeconds: 1,
            calibrationTickNanoseconds: 10_000_000,
            minimumCalibrationSamples: 1,
            maximumCalibrationSpreadDegrees: 2,
            defaults: defaults
        )

        viewModel.dismissOnboarding()
        viewModel.start()
        viewModel.beginCalibration()

        try? await Task.sleep(nanoseconds: 15_000_000)
        motion.emit(gravity: CMAcceleration(x: 0, y: 0.9, z: 0.1))
        motion.emit(gravity: CMAcceleration(x: 0, y: 0.9, z: 0.1))
        try? await Task.sleep(nanoseconds: 30_000_000)

        XCTAssertEqual(viewModel.calibrationFeedbackStyle, .failure)
        XCTAssertEqual(viewModel.statusText, "Calibration failed. Put the phone in your front pocket, let it settle, and try again.")
        XCTAssertEqual(haptics.calibrationStartCueCount, 1)
        XCTAssertEqual(haptics.calibrationFailureCueCount, 1)
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

    func emit(gravity: CMAcceleration) {
        handler?(MotionSnapshot(gravity: gravity, timestamp: 0))
    }
}

@MainActor
private func establishReadyState(
    viewModel: SessionViewModel,
    motion: MockMotionService,
    prepDelayNanoseconds: UInt64 = 20_000_000,
    settleDelayNanoseconds: UInt64 = 80_000_000,
    angles: [Double] = [5, 5, 5, 5]
) async {
    viewModel.dismissOnboarding()
    viewModel.start()
    motion.emit(angle: angles.first ?? 5)
    viewModel.beginCalibration()
    try? await Task.sleep(nanoseconds: prepDelayNanoseconds)
    for angle in angles {
        motion.emit(angle: angle)
    }
    let deadline = DispatchTime.now().uptimeNanoseconds + settleDelayNanoseconds
    while case .calibrating = viewModel.sessionPhase,
          DispatchTime.now().uptimeNanoseconds < deadline {
        try? await Task.sleep(nanoseconds: 5_000_000)
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
    private(set) var samplePulseCount = 0
    private(set) var calibrationStartCueCount = 0
    private(set) var calibrationSuccessCueCount = 0
    private(set) var calibrationFailureCueCount = 0

    func start() {}
    func update(deficit: Double) {}
    func playSamplePulse() {
        samplePulseCount += 1
    }
    func playCalibrationStartCue() {
        calibrationStartCueCount += 1
    }
    func playCalibrationSuccessCue() {
        calibrationSuccessCueCount += 1
    }
    func playCalibrationFailureCue() {
        calibrationFailureCueCount += 1
    }

    func stopAll() {
        stopCount += 1
    }
}
