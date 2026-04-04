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
    @Published private(set) var pocketConfirmed: Bool

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
        let storedPocketSide: PocketSide = defaults.string(forKey: Keys.pocketSide)
            .flatMap { PocketSide(rawValue: $0) } ?? .frontLeft
        let storedVolume = defaults.object(forKey: Keys.pulseVolume) as? Double ?? 0.6
        let storedHapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        let shouldShowOnboarding = !defaults.bool(forKey: Keys.onboardingDismissed)
        self.settings = AppSettings(pocketSide: storedPocketSide, targetAngle: storedTarget, pulseVolume: storedVolume, hapticsEnabled: storedHapticsEnabled)
        self.pocketConfirmed = defaults.bool(forKey: Keys.pocketConfirmed)
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
        guard settings.hapticsEnabled else {
            statusText = "Haptics are turned off."
            return
        }
        hapticsService.start()
        hapticsService.playSamplePulse()
        calibrationFeedbackStyle = .neutral
        statusText = "Sample pulse sent. If you do not feel it, make sure you are testing on a real iPhone."
    }

    func setTargetAngle(_ angle: Double) {
        let previousRounded = Int(settings.targetAngle.rounded())
        let clamped = min(max(angle, AppSettings.targetRange.lowerBound), AppSettings.targetRange.upperBound)
        settings.targetAngle = clamped.rounded()
        defaults.set(settings.targetAngle, forKey: Keys.targetAngle)
        if Int(settings.targetAngle.rounded()) != previousRounded {
            playSliderTick()
        }
        refreshStatusAndHaptics()
    }

    func setPocketSide(_ pocketSide: PocketSide) {
        settings.pocketSide = pocketSide
        defaults.set(pocketSide.rawValue, forKey: Keys.pocketSide)
        if !pocketConfirmed {
            pocketConfirmed = true
            defaults.set(true, forKey: Keys.pocketConfirmed)
        }
    }

    func setPulseVolume(_ volume: Double) {
        let clamped = min(max(volume, AppSettings.volumeRange.lowerBound), AppSettings.volumeRange.upperBound)
        settings.pulseVolume = clamped
        defaults.set(settings.pulseVolume, forKey: Keys.pulseVolume)
    }

    func setHapticsEnabled(_ enabled: Bool) {
        settings.hapticsEnabled = enabled
        defaults.set(enabled, forKey: Keys.hapticsEnabled)
        if !enabled {
            hapticsService.stopAll()
        } else if sessionPhase == .running {
            hapticsService.start()
            refreshStatusAndHaptics()
        }
    }

    func playTestTone() {
        pulseToneService.playTestTone(volume: Float(settings.pulseVolume))
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
        statusText = "Get ready. Put the phone in your \(settings.pocketSide.rawValue.lowercased()) pocket before capture begins."

        calibrationTask = Task { [weak self] in
            guard let self else { return }
            for remaining in stride(from: calibrationPrepSeconds, through: 1, by: -1) {
                guard runID == calibrationRunID else { return }
                calibrationStage = .preparing
                sessionPhase = .calibrating(secondsRemaining: remaining)
                statusText = "Get ready. Put the phone in your \(settings.pocketSide.rawValue.lowercased()) pocket. Capture starts in \(remaining)s."
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
            playCalibrationStartFeedback()

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
                statusText = "Calibration failed. Put the phone in your \(settings.pocketSide.rawValue.lowercased()) pocket, let it settle, and try again."
                calibrationFeedbackStyle = .failure
                calibrationBaselineBackup = nil
                playCalibrationFailureFeedback()
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
                playCalibrationSuccessFeedback()
            } else {
                baselineAngle = calibrationBaselineBackup
                sessionPhase = calibrationBaselineBackup == nil ? .idle : .ready
                statusText = "Calibration failed. Hold still, keep the phone settled, and try again."
                calibrationFeedbackStyle = .failure
                calibrationBaselineBackup = nil
                playCalibrationFailureFeedback()
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
        if settings.hapticsEnabled {
            hapticsService.start()
        }
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
                if self.settings.hapticsEnabled {
                    self.hapticsService.stopAll()
                }
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

        // Pause haptics (they don't work in background) but keep session alive
        if settings.hapticsEnabled {
            hapticsService.pause()
        }
        // Keep-alive tone ensures iOS doesn't suspend the process
        // Motion tracking and audio pulses continue in background
        if sessionPhase == .running {
            let deficit = max(0, settings.targetAngle - currentAngle)
            let zone = HapticZone.zone(for: deficit)
            if zone == .none || settings.pulseVolume <= 0 {
                pulseToneService.startKeepAlive()
            }
        }
    }

    func handleAppReturnedToForeground() {
        guard sessionPhase == .running || sessionPhase == .pausedPocketRemoved else { return }

        pulseToneService.stopKeepAlive()

        if settings.hapticsEnabled && sessionPhase == .running {
            hapticsService.start()
            let deficit = max(0, settings.targetAngle - currentAngle)
            hapticsService.resume(deficit: deficit)
        }
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
        proximityService.stop()
        hapticsService.stopAll()
        stopTonePulse()
    }

    var targetAngleText: String {
        "\(Int(settings.targetAngle.rounded()))°"
    }

    var currentAngleText: String {
        "\(Int(currentAngle.rounded()))°"
    }

    var targetProgress: Double {
        guard settings.targetAngle > 0 else { return 1 }
        return min(max(currentAngle / settings.targetAngle, 0), 1)
    }

    var canStartSession: Bool {
        sessionPhase == .ready && baselineAngle != nil
    }

    var shouldShowPlacementWarning: Bool {
        placementInvalid && (
            calibrationStage == .capturing ||
            sessionPhase == .running ||
            sessionPhase == .pausedPocketRemoved
        )
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
                if settings.hapticsEnabled {
                    hapticsService.stopAll()
                }
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
            if settings.hapticsEnabled {
                hapticsService.stopAll()
            }
            sessionPhase = .pausedPocketRemoved
            statusText = "Phone removed. Haptics paused."
        }
    }

    private func refreshStatusAndHaptics() {
        guard case .running = sessionPhase else {
            if sessionPhase != .pausedPocketRemoved {
                if settings.hapticsEnabled {
                    hapticsService.stopAll()
                }
                stopTonePulse()
            }
            if baselineAngle != nil, sessionPhase == .ready, calibrationFeedbackStyle == .neutral {
                statusText = "Baseline locked. Start when ready."
            }
            return
        }

        guard !placementInvalid else {
            if settings.hapticsEnabled {
                hapticsService.stopAll()
            }
            stopTonePulse()
            statusText = "Phone orientation invalid. Reinsert it top-up with the screen toward your thigh."
            return
        }

        guard pocketPresent else {
            if settings.hapticsEnabled {
                hapticsService.stopAll()
            }
            stopTonePulse()
            return
        }

        let deficit = max(0, settings.targetAngle - currentAngle)
        let zone = HapticZone.zone(for: deficit)
        statusText = zone.label
        if settings.hapticsEnabled {
            hapticsService.update(deficit: deficit)
        } else {
            hapticsService.stopAll()
        }
        updateTonePulse(zone: zone)
    }

    private func updateTonePulse(zone: HapticZone) {
        guard zone != currentToneZone else { return }
        currentToneZone = zone
        toneTimer?.invalidate()
        toneTimer = nil

        if zone == .none {
            // On target — stop coaching tones but start keep-alive for background persistence
            pulseToneService.startKeepAlive()
            return
        }

        // Active coaching zone — stop keep-alive, play real tones
        pulseToneService.stopKeepAlive()

        guard settings.pulseVolume > 0 else { return }

        let volume = Float(settings.pulseVolume)
        pulseToneService.playPulseTone(zone: zone, volume: volume)
        let timer = Timer(timeInterval: zone.interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.settings.pulseVolume > 0 {
                    self.pulseToneService.playPulseTone(zone: zone, volume: Float(self.settings.pulseVolume))
                }
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

    private func playCalibrationStartFeedback() {
        if settings.hapticsEnabled {
            hapticsService.playCalibrationStartCue()
        }
        pulseToneService.playCalibrationStartTone(volume: Float(settings.pulseVolume))
    }

    private func playCalibrationSuccessFeedback() {
        if settings.hapticsEnabled {
            hapticsService.playCalibrationSuccessCue()
        }
        pulseToneService.playCalibrationSuccessTone(volume: Float(settings.pulseVolume))
    }

    private func playCalibrationFailureFeedback() {
        if settings.hapticsEnabled {
            hapticsService.playCalibrationFailureCue()
        }
        pulseToneService.playCalibrationFailureTone(volume: Float(settings.pulseVolume))
    }

    private func playSliderTick() {
        guard settings.hapticsEnabled else { return }
        hapticsService.playSliderTick()
    }
}

private extension SessionViewModel {
    enum Keys {
        static let onboardingDismissed = "onboardingDismissed"
        static let targetAngle = "targetAngle"
        static let pocketSide = "pocketSide"
        static let pulseVolume = "pulseVolume"
        static let hapticsEnabled = "hapticsEnabled"
        static let pocketConfirmed = "pocketConfirmed"
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
