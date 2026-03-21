import CoreHaptics
import Foundation
import UIKit

protocol HapticsControlling {
    func start()
    func update(deficit: Double)
    func playSamplePulse()
    func playCalibrationStartCue()
    func playCalibrationSuccessCue()
    func playCalibrationFailureCue()
    func stopAll()
}

final class HapticsService: HapticsControlling {
    private var engine: CHHapticEngine?
    private var pulseTimer: Timer?
    private var cueTask: Task<Void, Never>?
    private var currentZone: HapticZone = .none
    private var engineRunning = false

    func start() {
        startEngineIfNeeded()
    }

    func update(deficit: Double) {
        let zone = HapticZone.zone(for: deficit)
        guard zone != currentZone else { return }
        currentZone = zone

        pulseTimer?.invalidate()
        pulseTimer = nil

        guard zone != .none else { return }

        playPulse(for: zone)
        let timer = Timer(timeInterval: zone.interval, repeats: true) { [weak self] _ in
            self?.playPulse(for: zone)
        }
        pulseTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func playSamplePulse() {
        playPulse(intensity: 0.58, sharpness: 0.24, includeUIKitOverlay: true)
    }

    func playCalibrationStartCue() {
        playCueSequence([
            CuePulse(delayNanoseconds: 0, intensity: 0.62, sharpness: 0.30, includeUIKitOverlay: true)
        ])
    }

    func playCalibrationSuccessCue() {
        playCueSequence([
            CuePulse(delayNanoseconds: 0, intensity: 0.56, sharpness: 0.20, includeUIKitOverlay: true),
            CuePulse(delayNanoseconds: 190_000_000, intensity: 0.72, sharpness: 0.28, includeUIKitOverlay: true)
        ])
    }

    func playCalibrationFailureCue() {
        playCueSequence([
            CuePulse(delayNanoseconds: 0, intensity: 0.36, sharpness: 0.18, includeUIKitOverlay: true),
            CuePulse(delayNanoseconds: 150_000_000, intensity: 0.46, sharpness: 0.22, includeUIKitOverlay: true),
            CuePulse(delayNanoseconds: 170_000_000, intensity: 0.60, sharpness: 0.28, includeUIKitOverlay: true)
        ])
    }

    func stopAll() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        cueTask?.cancel()
        cueTask = nil
        currentZone = .none
        engine?.stop(completionHandler: { _ in })
        engineRunning = false
    }

    private func playPulse(for zone: HapticZone) {
        playPulse(intensity: zone.intensity, sharpness: zone.sharpness, includeUIKitOverlay: false)
    }

    private func playPulse(intensity: Float, sharpness: Float, includeUIKitOverlay: Bool) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playUIKitFallback(intensity: intensity)
            return
        }
        guard startEngineIfNeeded() else {
            playUIKitFallback(intensity: intensity)
            return
        }

        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParameter, sharpnessParameter],
            relativeTime: 0
        )

        guard
            let pattern = try? CHHapticPattern(events: [event], parameters: []),
            let player = try? engine?.makePlayer(with: pattern)
        else {
            playUIKitFallback(intensity: intensity)
            return
        }

        try? player.start(atTime: 0)
        if includeUIKitOverlay {
            playUIKitFallback(intensity: intensity)
        }
    }

    private func playCueSequence(_ pulses: [CuePulse]) {
        cueTask?.cancel()
        cueTask = Task { [weak self] in
            guard let self else { return }
            for pulse in pulses {
                if pulse.delayNanoseconds > 0 {
                    try? await Task.sleep(nanoseconds: pulse.delayNanoseconds)
                }
                guard !Task.isCancelled else { return }
                self.playPulse(
                    intensity: pulse.intensity,
                    sharpness: pulse.sharpness,
                    includeUIKitOverlay: pulse.includeUIKitOverlay
                )
            }
        }
    }

    private func playUIKitFallback(intensity: Float) {
        DispatchQueue.main.async {
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            switch intensity {
            case ..<0.22:
                style = .soft
            case ..<0.48:
                style = .light
            default:
                style = .medium
            }
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred(intensity: min(max(CGFloat(intensity), 0.35), 1))
        }
    }

    @discardableResult
    private func startEngineIfNeeded() -> Bool {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return false }

        if engine == nil {
            guard let newEngine = try? CHHapticEngine() else { return false }
            newEngine.isAutoShutdownEnabled = true
            newEngine.stoppedHandler = { [weak self] _ in
                self?.engineRunning = false
            }
            newEngine.resetHandler = { [weak self] in
                self?.engineRunning = false
                self?.startEngineIfNeeded()
            }
            engine = newEngine
        }

        guard let engine else { return false }
        guard !engineRunning else { return true }
        do {
            try engine.start()
            engineRunning = true
            return true
        } catch {
            engineRunning = false
            return false
        }
    }
}

private struct CuePulse {
    let delayNanoseconds: UInt64
    let intensity: Float
    let sharpness: Float
    let includeUIKitOverlay: Bool
}

final class NoOpHapticsService: HapticsControlling {
    func start() {}
    func update(deficit: Double) {}
    func playSamplePulse() {}
    func playCalibrationStartCue() {}
    func playCalibrationSuccessCue() {}
    func playCalibrationFailureCue() {}
    func stopAll() {}
}
