import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var sessionPhase: SessionPhase
    @Published private(set) var currentAngle: Double = 0
    @Published private(set) var baselineAngle: Double?
    @Published private(set) var statusText: String = "Stand still to calibrate."
    @Published private(set) var placementInvalid = false
    @Published var showOnboarding: Bool

    private let motionService: MotionServiceProtocol
    private let proximityService: ProximityMonitoring
    private let hapticsService: HapticsControlling
    private let estimator = BendAngleEstimator()
    private let calibrationTickNanoseconds: UInt64
    private let minimumCalibrationSamples: Int
    private let maximumCalibrationSpreadDegrees: Double
    private let testingAutoPauseAfterNanoseconds: UInt64?
    private let defaults: UserDefaults

    private var smoother = ExponentialSmoother()
    private var calibrationAccumulator = CalibrationAccumulator()
    private var motionStarted = false
    private var calibrationTask: Task<Void, Never>?
    private var testingAutoPauseTask: Task<Void, Never>?
    private var pocketPresent = true
    private var calibrationBaselineBackup: Double?
    private var calibrationRunID = 0
    private var latestMotionSnapshot: MotionSnapshot?

    init(
        motionService: MotionServiceProtocol,
        proximityService: ProximityMonitoring,
        hapticsService: HapticsControlling,
        calibrationTickNanoseconds: UInt64 = 1_000_000_000,
        minimumCalibrationSamples: Int = 8,
        maximumCalibrationSpreadDegrees: Double = 2.25,
        testingAutoPauseAfterNanoseconds: UInt64? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.motionService = motionService
        self.proximityService = proximityService
        self.hapticsService = hapticsService
        self.calibrationTickNanoseconds = calibrationTickNanoseconds
        self.minimumCalibrationSamples = minimumCalibrationSamples
        self.maximumCalibrationSpreadDegrees = maximumCalibrationSpreadDegrees
        self.testingAutoPauseAfterNanoseconds = testingAutoPauseAfterNanoseconds
        self.defaults = defaults
        let storedTarget = defaults.object(forKey: Keys.targetAngle) as? Double ?? 20
        let storedPocketSide = PocketSide(rawValue: defaults.string(forKey: Keys.pocketSide) ?? "") ?? .right
        let shouldShowOnboarding = !defaults.bool(forKey: Keys.onboardingDismissed)
        self.settings = AppSettings(pocketSide: storedPocketSide, targetAngle: storedTarget)
        self.showOnboarding = shouldShowOnboarding
        self.sessionPhase = shouldShowOnboarding ? .onboarding : .idle
    }

    func start() {
        guard !motionStarted else { return }

        guard motionService.isAvailable else {
            sessionPhase = .unavailable("Motion data is unavailable on this device.")
            statusText = "Motion data is unavailable."
            return
        }

        motionStarted = true
        motionService.start { [weak self] snapshot in
            self?.handleMotion(snapshot)
        }
    }

    func dismissOnboarding() {
        showOnboarding = false
        defaults.set(true, forKey: Keys.onboardingDismissed)
        if sessionPhase == .onboarding {
            sessionPhase = baselineAngle == nil ? .idle : .ready
        }
    }

    func reopenOnboarding() {
        showOnboarding = true
    }

    func playHapticSample() {
        hapticsService.playSamplePulse()
    }

    func setTargetAngle(_ angle: Double) {
        let clamped = min(max(angle, AppSettings.targetRange.lowerBound), AppSettings.targetRange.upperBound)
        settings.targetAngle = clamped.rounded()
        defaults.set(settings.targetAngle, forKey: Keys.targetAngle)
        refreshStatusAndHaptics()
    }

    func setPocketSide(_ pocketSide: PocketSide) {
        settings.pocketSide = pocketSide
        defaults.set(pocketSide.rawValue, forKey: Keys.pocketSide)
        if let latestMotionSnapshot {
            placementInvalid = !estimator.isPlacementValid(
                gravity: latestMotionSnapshot.gravity,
                pocketSide: settings.pocketSide
            )
        }
        refreshStatusAndHaptics()
    }

    func beginCalibration() {
        if case .unavailable = sessionPhase {
            statusText = "Motion data is unavailable."
            return
        }

        calibrationTask?.cancel()
        calibrationRunID += 1
        let runID = calibrationRunID
        hapticsService.stopAll()
        calibrationAccumulator.reset()
        smoother.reset()
        placementInvalid = false
        calibrationBaselineBackup = baselineAngle
        baselineAngle = nil
        currentAngle = 0
        sessionPhase = .calibrating(secondsRemaining: 3)
        statusText = "Hold still. We need a steady standing baseline."

        calibrationTask = Task { [weak self] in
            guard let self else { return }
            for remaining in stride(from: 3, through: 1, by: -1) {
                guard runID == calibrationRunID else { return }
                sessionPhase = .calibrating(secondsRemaining: remaining)
                do {
                    try await Task.sleep(nanoseconds: calibrationTickNanoseconds)
                    try Task.checkCancellation()
                } catch {
                    guard runID == calibrationRunID else { return }
                    restoreCalibrationBackup()
                    return
                }
            }

            guard runID == calibrationRunID else { return }

            if calibrationAccumulator.isStable(
                minimumSamples: minimumCalibrationSamples,
                maximumSpread: maximumCalibrationSpreadDegrees
            ), let baseline = calibrationAccumulator.average {
                baselineAngle = baseline
                calibrationBaselineBackup = nil
                sessionPhase = .ready
                statusText = "Baseline locked. Start when ready."
                refreshStatusAndHaptics()
            } else {
                baselineAngle = calibrationBaselineBackup
                sessionPhase = calibrationBaselineBackup == nil ? .idle : .ready
                statusText = calibrationBaselineBackup == nil
                    ? "Calibration failed. Hold still and keep the phone settled."
                    : "Calibration failed. Previous baseline kept."
                calibrationBaselineBackup = nil
            }
        }
    }

    func startSession() {
        guard sessionPhase == .ready, baselineAngle != nil else {
            statusText = "Finish calibration before starting."
            return
        }
        guard !placementInvalid else {
            statusText = "Phone orientation invalid. Reinsert it top-up with the screen toward your thigh."
            return
        }

        calibrationTask?.cancel()
        UIApplication.shared.isIdleTimerDisabled = true
        hapticsService.start()
        pocketPresent = true
        testingAutoPauseTask?.cancel()
        sessionPhase = .running
        statusText = "Session live."
        proximityService.start { [weak self] isNear in
            self?.handleProximityChange(isNear)
        }
        refreshStatusAndHaptics()

        if let delay = testingAutoPauseAfterNanoseconds {
            testingAutoPauseTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: delay)
                guard let self, self.sessionPhase == .running else { return }
                self.pocketPresent = false
                self.hapticsService.stopAll()
                self.sessionPhase = .pausedPocketRemoved
                self.statusText = "Phone removed. Haptics paused."
            }
        }
    }

    func handleAppMovedOutOfForeground() {
        if case .calibrating = sessionPhase {
            calibrationTask?.cancel()
            calibrationRunID += 1
            restoreCalibrationBackup()
            statusText = "Calibration paused because the app left the foreground."
            return
        }

        guard sessionPhase == .running || sessionPhase == .pausedPocketRemoved else { return }
        stopSession()
        statusText = "Session paused because the app left the foreground."
    }

    func stopSession() {
        calibrationTask?.cancel()
        calibrationRunID += 1
        testingAutoPauseTask?.cancel()
        if case .calibrating = sessionPhase {
            restoreCalibrationBackup()
        }
        sessionPhase = baselineAngle == nil ? .idle : .ready
        statusText = baselineAngle == nil ? "Stand still to calibrate." : "Session stopped."
        UIApplication.shared.isIdleTimerDisabled = false
        proximityService.stop()
        hapticsService.stopAll()
    }

    var targetAngleText: String {
        "\(Int(settings.targetAngle.rounded()))°"
    }

    var setupTargetExampleText: String {
        "Example: if you stand at 6° and choose \(targetAngleText), the app will coach you toward about \(Int((settings.targetAngle + 6).rounded()))° live tilt."
    }

    var currentAngleText: String {
        "\(Int(currentAngle.rounded()))°"
    }

    var targetProgress: Double {
        guard settings.targetAngle > 0 else { return 1 }
        return min(max(currentAngle / settings.targetAngle, 0), 1)
    }

    var primarySessionTitle: String {
        if placementInvalid {
            return "Check Placement"
        }
        switch sessionPhase {
        case .pausedPocketRemoved:
            return "Phone Removed"
        case .running:
            return targetProgress >= 1 ? "On Target" : "Below Target"
        case .ready:
            return "Ready To Skate"
        case .calibrating:
            return "Calibrating"
        case .unavailable:
            return "Motion Unavailable"
        case .onboarding, .idle:
            return "Setup"
        }
    }

    var primarySessionDetail: String {
        if placementInvalid {
            return "Put the phone back top-up with the screen against your thigh, then let it settle before you keep skating."
        }
        switch sessionPhase {
        case .pausedPocketRemoved:
            return "Coaching is paused. Put the phone back in your front pocket and it will resume automatically."
        case .running:
            return targetProgress >= 1
                ? "Stay there. You are meeting your bend target, so haptics stay quiet."
                : "Bend a little more through your knees until the live number reaches your target."
        default:
            return guidanceText
        }
    }

    var sessionBadgeText: String {
        if placementInvalid {
            return "Placement Invalid"
        }
        switch sessionPhase {
        case .pausedPocketRemoved:
            return "Phone Removed"
        case .running:
            return targetProgress >= 1 ? "On Target" : "Below Target"
        default:
            return statusText
        }
    }

    var sessionBadgeSymbol: String {
        if placementInvalid {
            return "exclamationmark.triangle.fill"
        }
        switch sessionPhase {
        case .pausedPocketRemoved:
            return "pause.fill"
        case .running:
            return targetProgress >= 1 ? "checkmark.circle.fill" : "figure.skating"
        default:
            return "dot.radiowaves.left.and.right"
        }
    }

    var secondaryMetricText: String {
        if let baselineAngle {
            return "Standing baseline \(Int(baselineAngle.rounded()))°"
        }
        return "Standing baseline not set"
    }

    var setupSummaryTitle: String {
        if baselineAngle != nil {
            return "Setup Locked In"
        }
        return "Skating Setup"
    }

    var setupSummaryDetail: String {
        if baselineAngle != nil {
            return "Baseline ready. Keep using your \(settings.pocketSide.rawValue.lowercased()) front pocket and start when you are ready to roll."
        }
        return "Set your pocket and bend goal first, then calibrate upright before you skate."
    }

    var setupStepTitle: String {
        switch sessionPhase {
        case .calibrating:
            return "3. Calibrating Upright"
        case .ready:
            return "4. Start Session"
        default:
            return "3. Calibrate Upright"
        }
    }

    var guidanceText: String {
        if placementInvalid {
            return "Phone placement looks off. Keep it top-up with the screen toward your thigh before you calibrate or skate."
        }
        switch sessionPhase {
        case .running:
            return "Keep the app open and awake while you skate. Do not background it or the session will pause."
        case .pausedPocketRemoved:
            return "Phone removed. Haptics pause until the phone is back in your front pocket."
        case .ready:
            return "Calibration complete. Your target is extra bend beyond your natural standing posture."
        case .calibrating(let secondsRemaining):
            return "Stand upright and still for a steady reading. \(secondsRemaining)s remaining."
        case .unavailable(let message):
            return message
        case .onboarding, .idle:
            return "Use your \(settings.pocketSide.rawValue.lowercased()) front pocket, keep the phone top-up with the screen toward your thigh, then calibrate upright."
        }
    }

    var canStartSession: Bool {
        sessionPhase == .ready && !placementInvalid
    }

    var startSessionHelperText: String {
        if placementInvalid {
            return "Fix phone placement before starting. Keep it top-up with the screen against your thigh."
        }
        if baselineAngle == nil {
            return "Pick your setup, calibrate upright, then start when the app says ready."
        }
        return "Keep the app open and in the foreground while you skate. Locking or leaving the app pauses coaching."
    }

    private func handleMotion(_ snapshot: MotionSnapshot) {
        latestMotionSnapshot = snapshot
        placementInvalid = !estimator.isPlacementValid(gravity: snapshot.gravity, pocketSide: settings.pocketSide)
        if placementInvalid {
            currentAngle = 0
            if sessionPhase == .running {
                hapticsService.stopAll()
            }
            if sessionPhase != .pausedPocketRemoved {
                statusText = "Phone orientation invalid. Reinsert it top-up with the screen toward your thigh."
            }
            return
        }

        let rawAngle = estimator.rawAngleDegrees(gravity: snapshot.gravity, pocketSide: settings.pocketSide)
        let smoothed = smoother.add(rawAngle)

        if case .calibrating = sessionPhase {
            calibrationAccumulator.add(smoothed)
        }

        if let baselineAngle {
            currentAngle = max(0, smoothed - baselineAngle)
        } else {
            currentAngle = max(0, smoothed)
        }

        refreshStatusAndHaptics()
    }

    private func handleProximityChange(_ isNear: Bool) {
        pocketPresent = isNear
        guard sessionPhase == .running || sessionPhase == .pausedPocketRemoved else { return }

        if isNear {
            if sessionPhase == .pausedPocketRemoved {
                sessionPhase = .running
                statusText = "Phone returned. Session live."
                refreshStatusAndHaptics()
            }
        } else {
            hapticsService.stopAll()
            sessionPhase = .pausedPocketRemoved
            statusText = "Phone removed. Haptics paused."
        }
    }

    private func refreshStatusAndHaptics() {
        guard case .running = sessionPhase else {
            if sessionPhase != .pausedPocketRemoved {
                hapticsService.stopAll()
            }
            if baselineAngle != nil, sessionPhase == .ready {
                statusText = "Baseline locked. Start when ready."
            }
            return
        }

        guard !placementInvalid else {
            hapticsService.stopAll()
            statusText = "Phone orientation invalid. Reinsert it top-up with the screen toward your thigh."
            return
        }

        guard pocketPresent else {
            hapticsService.stopAll()
            return
        }

        let deficit = max(0, settings.targetAngle - currentAngle)
        let zone = HapticZone.zone(for: deficit)
        statusText = zone.label
        hapticsService.update(deficit: deficit)
    }

    private func restoreCalibrationBackup() {
        let restoredBaseline = calibrationBaselineBackup ?? baselineAngle
        baselineAngle = restoredBaseline
        sessionPhase = restoredBaseline == nil ? .idle : .ready
        calibrationBaselineBackup = nil
    }
}

private extension SessionViewModel {
    enum Keys {
        static let onboardingDismissed = "onboardingDismissed"
        static let targetAngle = "targetAngle"
        static let pocketSide = "pocketSide"
    }
}
