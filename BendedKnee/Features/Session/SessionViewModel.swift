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
    @Published private(set) var calibrationStage: CalibrationStage?
    @Published private(set) var calibrationFeedbackStyle: CalibrationFeedbackStyle = .neutral

    private let motionService: MotionServiceProtocol
    private let proximityService: ProximityMonitoring
    private let hapticsService: HapticsControlling
    private let pulseToneService: PulseToneControlling
    private let estimator = BendAngleEstimator()
    private let calibrationPrepSeconds: Int
    private let calibrationCaptureSeconds: Int
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
    private var hasAttemptedSessionStart = false
    private var calibrationValidSampleCount = 0
    private var calibrationInvalidSampleCount = 0
    private var toneTimer: Timer?
    private var currentToneZone: HapticZone = .none

    init(
        motionService: MotionServiceProtocol,
        proximityService: ProximityMonitoring,
        hapticsService: HapticsControlling,
        pulseToneService: PulseToneControlling = NoOpPulseToneService(),
        calibrationPrepSeconds: Int = 1,
        calibrationCaptureSeconds: Int = 3,
        calibrationTickNanoseconds: UInt64 = 1_000_000_000,
        minimumCalibrationSamples: Int = 8,
        maximumCalibrationSpreadDegrees: Double = 2.25,
        testingAutoPauseAfterNanoseconds: UInt64? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.motionService = motionService
        self.proximityService = proximityService
        self.hapticsService = hapticsService
        self.pulseToneService = pulseToneService
        self.calibrationPrepSeconds = calibrationPrepSeconds
        self.calibrationCaptureSeconds = calibrationCaptureSeconds
        self.calibrationTickNanoseconds = calibrationTickNanoseconds
        self.minimumCalibrationSamples = minimumCalibrationSamples
        self.maximumCalibrationSpreadDegrees = maximumCalibrationSpreadDegrees
        self.testingAutoPauseAfterNanoseconds = testingAutoPauseAfterNanoseconds
        self.defaults = defaults
        let storedTarget = defaults.object(forKey: Keys.targetAngle) as? Double ?? 20
        let storedPocketSide = PocketSide(rawValue: defaults.string(forKey: Keys.pocketSide) ?? "") ?? .right
        let storedVolume = defaults.object(forKey: Keys.pulseVolume) as? Double ?? 0.6
        let storedAudioEnabled = defaults.object(forKey: Keys.pulseAudioEnabled) as? Bool ?? true
        let shouldShowOnboarding = !defaults.bool(forKey: Keys.onboardingDismissed)
        self.settings = AppSettings(pocketSide: storedPocketSide, targetAngle: storedTarget, pulseVolume: storedVolume, pulseAudioEnabled: storedAudioEnabled)
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

    func playHapticSample() {
        hapticsService.start()
        hapticsService.playSamplePulse()
        calibrationFeedbackStyle = .neutral
        statusText = "Sample pulse sent. If you do not feel it, make sure you are testing on a real iPhone."
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

    func setPulseVolume(_ volume: Double) {
        let clamped = min(max(volume, AppSettings.volumeRange.lowerBound), AppSettings.volumeRange.upperBound)
        settings.pulseVolume = clamped
        defaults.set(settings.pulseVolume, forKey: Keys.pulseVolume)
    }

    func setPulseAudioEnabled(_ enabled: Bool) {
        settings.pulseAudioEnabled = enabled
        defaults.set(enabled, forKey: Keys.pulseAudioEnabled)
        if !enabled {
            pulseToneService.stop()
        }
    }

    func playTestTone() {
        let volume = settings.pulseAudioEnabled ? Float(settings.pulseVolume) : 0
        pulseToneService.playTestTone(volume: volume)
    }

    func beginCalibration() {
        if case .unavailable = sessionPhase {
            statusText = "Motion data is unavailable."
            return
        }

        hasAttemptedSessionStart = false
        calibrationTask?.cancel()
        calibrationRunID += 1
        let runID = calibrationRunID
        hapticsService.stopAll()
        calibrationAccumulator.reset()
        calibrationValidSampleCount = 0
        calibrationInvalidSampleCount = 0
        placementInvalid = false
        calibrationBaselineBackup = baselineAngle
        currentAngle = 0
        calibrationStage = .preparing
        calibrationFeedbackStyle = .preparing
        sessionPhase = .calibrating(secondsRemaining: calibrationPrepSeconds)
        statusText = "Get ready. Put the phone in your front pocket before capture begins."

        calibrationTask = Task { [weak self] in
            guard let self else { return }
            for remaining in stride(from: calibrationPrepSeconds, through: 1, by: -1) {
                guard runID == calibrationRunID else { return }
                calibrationStage = .preparing
                sessionPhase = .calibrating(secondsRemaining: remaining)
                statusText = "Get ready. Put the phone in your front pocket. Capture starts in \(remaining)s."
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

            calibrationStage = .capturing
            calibrationFeedbackStyle = .capturing
            calibrationAccumulator.reset()
            calibrationValidSampleCount = 0
            calibrationInvalidSampleCount = 0
            smoother.reset()
            currentAngle = 0
            placementInvalid = false
            statusText = "Calibration started. Stand upright and stay still."
            hapticsService.playCalibrationStartCue()

            for remaining in stride(from: calibrationCaptureSeconds, through: 1, by: -1) {
                guard runID == calibrationRunID else { return }
                calibrationStage = .capturing
                sessionPhase = .calibrating(secondsRemaining: remaining)
                statusText = "Calibrating now. Stay upright and still. \(remaining)s remaining."
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
            calibrationStage = nil

            let calibrationPlacementFailed =
                calibrationValidSampleCount < minimumCalibrationSamples ||
                calibrationInvalidSampleCount > max(6, calibrationValidSampleCount / 2)

            if placementInvalid || calibrationPlacementFailed {
                baselineAngle = calibrationBaselineBackup
                sessionPhase = calibrationBaselineBackup == nil ? .idle : .ready
                statusText = "Calibration failed. Put the phone in your front pocket, let it settle, and try again."
                calibrationFeedbackStyle = .failure
                calibrationBaselineBackup = nil
                hapticsService.playCalibrationFailureCue()
                return
            }

            if calibrationAccumulator.isStable(
                minimumSamples: minimumCalibrationSamples,
                maximumSpread: maximumCalibrationSpreadDegrees
            ), let baseline = calibrationAccumulator.average {
                baselineAngle = baseline
                calibrationBaselineBackup = nil
                hasAttemptedSessionStart = false
                placementInvalid = false
                sessionPhase = .ready
                statusText = "Calibration complete. Baseline locked. You can take the phone out and start when ready."
                calibrationFeedbackStyle = .success
                hapticsService.playCalibrationSuccessCue()
            } else {
                baselineAngle = calibrationBaselineBackup
                sessionPhase = calibrationBaselineBackup == nil ? .idle : .ready
                statusText = "Calibration failed. Hold still, keep the phone settled, and try again."
                calibrationFeedbackStyle = .failure
                calibrationBaselineBackup = nil
                hapticsService.playCalibrationFailureCue()
            }
        }
    }

    func startSession() {
        hasAttemptedSessionStart = true
        guard sessionPhase == .ready, baselineAngle != nil else {
            statusText = "Finish calibration before starting."
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
        calibrationStage = nil
        hasAttemptedSessionStart = false
        sessionPhase = baselineAngle == nil ? .idle : .ready
        statusText = baselineAngle == nil ? "Stand still to calibrate." : "Session stopped."
        UIApplication.shared.isIdleTimerDisabled = false
        proximityService.stop()
        hapticsService.stopAll()
        stopTonePulse()
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
            return "Skating Setup"
        }
        return "Skating Setup"
    }

    var setupSummaryDetail: String {
        if baselineAngle != nil {
            return "Baseline ready. Fine-tune pocket side or target below any time before you start skating."
        }
        return "Open this guide for placement rules, then fine-tune your pocket side and target below."
    }

    var setupStepTitle: String {
        "Calibrate Upright"
    }

    var guidanceText: String {
        if shouldShowPlacementWarning {
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
            switch calibrationStage {
            case .preparing:
                return "Put the phone in your front pocket during the countdown. Capture starts in \(secondsRemaining)s."
            case .capturing:
                return "Stand upright and hold still. \(secondsRemaining)s remaining."
            case .none:
                return "Calibration is preparing."
            }
        case .unavailable(let message):
            return message
        case .onboarding, .idle:
            return "Use your \(settings.pocketSide.rawValue.lowercased()) front pocket, keep the phone top-up with the screen toward your thigh, then calibrate upright."
        }
    }

    var canStartSession: Bool {
        sessionPhase == .ready && baselineAngle != nil
    }

    var startSessionHelperText: String {
        if baselineAngle == nil {
            return "Pick your setup, calibrate upright, then start when the app says ready."
        }
        return "Keep the app open and in the foreground while you skate. Locking or leaving the app pauses coaching."
    }

    var shouldShowPlacementWarning: Bool {
        placementInvalid && (
            calibrationStage == .capturing ||
            sessionPhase == .running ||
            sessionPhase == .pausedPocketRemoved
        )
    }

    var calibrationBannerTitle: String {
        switch calibrationFeedbackStyle {
        case .preparing:
            return "Get Ready"
        case .capturing:
            return "Capturing Standing Baseline"
        case .success:
            return "Calibration Successful"
        case .failure:
            return "Calibration Needs Another Try"
        case .neutral:
            return baselineAngle == nil ? "Calibration Not Started" : "Baseline Ready"
        }
    }

    var calibrationBannerDetail: String {
        switch calibrationFeedbackStyle {
        case .preparing:
            return "You have \(calibrationPrepSeconds) seconds to place the phone in your pocket before capture begins."
        case .capturing:
            return "Once capture starts, stay upright and quiet until the countdown finishes. Drop ignores brief pocket-settling noise but still needs a mostly stable capture."
        case .success:
            return "Baseline saved. A double pulse marks completion so you know you can look at the phone again."
        case .failure:
            return "If the phone was moving, upside down, or not settled in your pocket, try calibration again."
        case .neutral:
            return "The app compares your live bend against this upright standing baseline."
        }
    }

    private func handleMotion(_ snapshot: MotionSnapshot) {
        latestMotionSnapshot = snapshot
        if calibrationStage == .preparing {
            placementInvalid = false
            return
        }

        let placementLooksValid = estimator.isPlacementValid(gravity: snapshot.gravity, pocketSide: settings.pocketSide)
        if calibrationStage == .capturing {
            if placementLooksValid {
                calibrationValidSampleCount += 1
                placementInvalid = false
            } else {
                calibrationInvalidSampleCount += 1
                placementInvalid = calibrationValidSampleCount == 0 || calibrationInvalidSampleCount > max(6, calibrationValidSampleCount / 2)
                return
            }
        } else {
            placementInvalid = !placementLooksValid
        }

        if placementInvalid {
            currentAngle = 0
            if sessionPhase == .running {
                hapticsService.stopAll()
            }
            if shouldShowPlacementWarning && sessionPhase != .pausedPocketRemoved {
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
                stopTonePulse()
            }
            if baselineAngle != nil, sessionPhase == .ready, calibrationFeedbackStyle == .neutral {
                statusText = "Baseline locked. Start when ready."
            }
            return
        }

        guard !placementInvalid else {
            hapticsService.stopAll()
            stopTonePulse()
            statusText = "Phone orientation invalid. Reinsert it top-up with the screen toward your thigh."
            return
        }

        guard pocketPresent else {
            hapticsService.stopAll()
            stopTonePulse()
            return
        }

        let deficit = max(0, settings.targetAngle - currentAngle)
        let zone = HapticZone.zone(for: deficit)
        statusText = zone.label
        hapticsService.update(deficit: deficit)
        updateTonePulse(zone: zone)
    }

    private func updateTonePulse(zone: HapticZone) {
        guard zone != currentToneZone else { return }
        currentToneZone = zone
        toneTimer?.invalidate()
        toneTimer = nil

        guard zone != .none, settings.pulseAudioEnabled, settings.pulseVolume > 0 else { return }

        let volume = Float(settings.pulseVolume)
        pulseToneService.playPulseTone(zone: zone, volume: volume)
        let timer = Timer(timeInterval: zone.interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.settings.pulseAudioEnabled && self.settings.pulseVolume > 0 {
                self.pulseToneService.playPulseTone(zone: zone, volume: Float(self.settings.pulseVolume))
            }
        }
        toneTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopTonePulse() {
        toneTimer?.invalidate()
        toneTimer = nil
        currentToneZone = .none
        pulseToneService.stop()
    }

    private func restoreCalibrationBackup() {
        let restoredBaseline = calibrationBaselineBackup ?? baselineAngle
        baselineAngle = restoredBaseline
        calibrationValidSampleCount = 0
        calibrationInvalidSampleCount = 0
        calibrationStage = nil
        calibrationFeedbackStyle = .neutral
        sessionPhase = restoredBaseline == nil ? .idle : .ready
        calibrationBaselineBackup = nil
    }
}

private extension SessionViewModel {
    enum Keys {
        static let onboardingDismissed = "onboardingDismissed"
        static let targetAngle = "targetAngle"
        static let pocketSide = "pocketSide"
        static let pulseVolume = "pulseVolume"
        static let pulseAudioEnabled = "pulseAudioEnabled"
    }
}

enum CalibrationStage: Equatable {
    case preparing
    case capturing
}

enum CalibrationFeedbackStyle: Equatable {
    case neutral
    case preparing
    case capturing
    case success
    case failure
}
