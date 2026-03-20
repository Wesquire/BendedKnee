import Combine
import Foundation
import UIKit

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var sessionPhase: SessionPhase
    @Published private(set) var currentAngle: Double = 0
    @Published private(set) var baselineAngle: Double?
    @Published private(set) var statusText: String = "Stand still to calibrate."
    @Published var showOnboarding: Bool

    private let motionService: MotionServiceProtocol
    private let proximityService: ProximityMonitoring
    private let hapticsService: HapticsControlling
    private let estimator = BendAngleEstimator()
    private let calibrationTickNanoseconds: UInt64
    private let minimumCalibrationSamples: Int
    private let maximumCalibrationSpreadDegrees: Double
    private let defaults: UserDefaults

    private var smoother = ExponentialSmoother()
    private var calibrationAccumulator = CalibrationAccumulator()
    private var motionStarted = false
    private var calibrationTask: Task<Void, Never>?
    private var pocketPresent = true

    init(
        motionService: MotionServiceProtocol,
        proximityService: ProximityMonitoring,
        hapticsService: HapticsControlling,
        calibrationTickNanoseconds: UInt64 = 1_000_000_000,
        minimumCalibrationSamples: Int = 8,
        maximumCalibrationSpreadDegrees: Double = 2.25,
        defaults: UserDefaults = .standard
    ) {
        self.motionService = motionService
        self.proximityService = proximityService
        self.hapticsService = hapticsService
        self.calibrationTickNanoseconds = calibrationTickNanoseconds
        self.minimumCalibrationSamples = minimumCalibrationSamples
        self.maximumCalibrationSpreadDegrees = maximumCalibrationSpreadDegrees
        self.defaults = defaults
        let storedTarget = defaults.object(forKey: Keys.targetAngle) as? Double ?? 20
        let shouldShowOnboarding = !defaults.bool(forKey: Keys.onboardingDismissed)
        self.settings = AppSettings(targetAngle: storedTarget)
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

    func setTargetAngle(_ angle: Double) {
        let clamped = min(max(angle, AppSettings.targetRange.lowerBound), AppSettings.targetRange.upperBound)
        settings.targetAngle = clamped.rounded()
        defaults.set(settings.targetAngle, forKey: Keys.targetAngle)
        refreshStatusAndHaptics()
    }

    func beginCalibration() {
        if case .unavailable = sessionPhase {
            statusText = "Motion data is unavailable."
            return
        }

        calibrationTask?.cancel()
        hapticsService.stopAll()
        calibrationAccumulator.reset()
        smoother.reset()
        baselineAngle = nil
        currentAngle = 0
        statusText = "Hold still. We need a steady standing baseline."

        calibrationTask = Task { [weak self] in
            guard let self else { return }
            for remaining in stride(from: 3, through: 1, by: -1) {
                sessionPhase = .calibrating(secondsRemaining: remaining)
                try? await Task.sleep(nanoseconds: calibrationTickNanoseconds)
            }

            if calibrationAccumulator.isStable(
                minimumSamples: minimumCalibrationSamples,
                maximumSpread: maximumCalibrationSpreadDegrees
            ), let baseline = calibrationAccumulator.average {
                baselineAngle = baseline
                sessionPhase = .ready
                statusText = "Baseline locked. Start when ready."
                refreshStatusAndHaptics()
            } else {
                sessionPhase = .idle
                statusText = "Calibration failed. Hold still and keep the phone settled."
            }
        }
    }

    func startSession() {
        guard baselineAngle != nil else {
            statusText = "Calibrate before starting."
            return
        }

        UIApplication.shared.isIdleTimerDisabled = true
        hapticsService.start()
        pocketPresent = true
        proximityService.start { [weak self] isNear in
            self?.handleProximityChange(isNear)
        }
        sessionPhase = .running
        statusText = "Session live."
        refreshStatusAndHaptics()
    }

    func stopSession() {
        calibrationTask?.cancel()
        sessionPhase = baselineAngle == nil ? .idle : .ready
        statusText = baselineAngle == nil ? "Stand still to calibrate." : "Session stopped."
        UIApplication.shared.isIdleTimerDisabled = false
        proximityService.stop()
        hapticsService.stopAll()
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

    var primarySessionTitle: String {
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
        switch sessionPhase {
        case .pausedPocketRemoved:
            return "Coaching is paused until the phone is back in your front pocket."
        case .running:
            return targetProgress >= 1
                ? "Stay here. Haptics are quiet because you are meeting your bend target."
                : "Stay lower through your knees until the live bend reaches your target."
        default:
            return guidanceText
        }
    }

    var sessionBadgeText: String {
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

    var guidanceText: String {
        switch sessionPhase {
        case .running:
            return "Keep the app open. The session screen stays awake so tracking does not get suspended."
        case .pausedPocketRemoved:
            return "Phone removed. Haptics pause until the phone is back in your front pocket."
        case .ready:
            return "Calibrated. The target means extra bend beyond your standing posture."
        case .calibrating(let secondsRemaining):
            return "Stand upright and still. We are checking for a steady standing window. \(secondsRemaining)s remaining."
        case .unavailable(let message):
            return message
        case .onboarding, .idle:
            return "Calibrate while standing upright with the phone in either front pocket, top-up and screen toward your thigh."
        }
    }

    private func handleMotion(_ snapshot: MotionSnapshot) {
        let rawAngle = estimator.rawAngleDegrees(gravity: snapshot.gravity)
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

        guard pocketPresent else {
            hapticsService.stopAll()
            return
        }

        let deficit = max(0, settings.targetAngle - currentAngle)
        let zone = HapticZone.zone(for: deficit)
        statusText = zone.label
        hapticsService.update(deficit: deficit)
    }
}

private extension SessionViewModel {
    enum Keys {
        static let onboardingDismissed = "onboardingDismissed"
        static let targetAngle = "targetAngle"
    }
}
