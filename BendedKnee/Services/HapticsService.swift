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
    func playSliderTick()
    func pause()
    func resume(deficit: Double)
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
        startEngineIfNeeded()
        // Play gentle, then medium, then strong in quick succession so the user feels the rhythmic difference
        playCueSequence([
            // Gentle: single tap
            CuePulse(delayNanoseconds: 0, intensity: 0.75, sharpness: 0.55, includeUIKitOverlay: true),
            // Medium: double-tap
            CuePulse(delayNanoseconds: 500_000_000, intensity: 0.90, sharpness: 0.75, includeUIKitOverlay: true),
            CuePulse(delayNanoseconds: 90_000_000, intensity: 0.90, sharpness: 0.75, includeUIKitOverlay: false),
            // Strong: triple-tap
            CuePulse(delayNanoseconds: 500_000_000, intensity: 1.0, sharpness: 1.0, includeUIKitOverlay: true),
            CuePulse(delayNanoseconds: 80_000_000, intensity: 1.0, sharpness: 1.0, includeUIKitOverlay: false),
            CuePulse(delayNanoseconds: 80_000_000, intensity: 1.0, sharpness: 1.0, includeUIKitOverlay: false)
        ])
    }

    func playCalibrationStartCue() {
        startEngineIfNeeded()
        // Single firm tap — capture has begun
        playCueSequence([
            CuePulse(delayNanoseconds: 0, intensity: 0.95, sharpness: 0.60, includeUIKitOverlay: true)
        ])
    }

    func playCalibrationSuccessCue() {
        startEngineIfNeeded()
        // Rising two-tap — feels like arrival
        playCueSequence([
            CuePulse(delayNanoseconds: 0, intensity: 0.80, sharpness: 0.45, includeUIKitOverlay: true),
            CuePulse(delayNanoseconds: 200_000_000, intensity: 1.0, sharpness: 0.70, includeUIKitOverlay: true)
        ])
    }

    func playCalibrationFailureCue() {
        startEngineIfNeeded()
        // Descending two-tap — gentle "not yet"
        playCueSequence([
            CuePulse(delayNanoseconds: 0, intensity: 0.85, sharpness: 0.55, includeUIKitOverlay: true),
            CuePulse(delayNanoseconds: 180_000_000, intensity: 0.50, sharpness: 0.30, includeUIKitOverlay: true)
        ])
    }

    func playSliderTick() {
        DispatchQueue.main.async {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }

    func pause() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        cueTask?.cancel()
        cueTask = nil
        engine?.stop(completionHandler: { _ in })
        engineRunning = false
    }

    func resume(deficit: Double) {
        currentZone = .none
        update(deficit: deficit)
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
        playRhythmicPattern(for: zone)
    }

    /// Plays a rhythmic haptic pattern:
    /// - Gentle: single tap
    /// - Medium: double-tap (90ms apart)
    /// - Strong: triple rapid pulse (80ms apart)
    private func playRhythmicPattern(for zone: HapticZone) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playUIKitFallback(intensity: zone.intensity)
            return
        }
        guard startEngineIfNeeded() else {
            playUIKitFallback(intensity: zone.intensity)
            return
        }

        let tapCount: Int
        let gapSeconds: Double
        switch zone {
        case .none:
            return
        case .gentle:
            tapCount = 1
            gapSeconds = 0
        case .medium:
            tapCount = 2
            gapSeconds = 0.09
        case .strong:
            tapCount = 3
            gapSeconds = 0.08
        }

        var events: [CHHapticEvent] = []
        for i in 0..<tapCount {
            let time = Double(i) * gapSeconds
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: zone.intensity)
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: zone.sharpness)
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: time
            ))
        }

        guard
            let pattern = try? CHHapticPattern(events: events, parameters: []),
            let player = try? engine?.makePlayer(with: pattern)
        else {
            playUIKitFallback(intensity: zone.intensity)
            return
        }

        try? player.start(atTime: 0)
        playUIKitFallback(intensity: zone.intensity)
    }

    private func playSinglePulse(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playUIKitFallback(intensity: intensity)
            return
        }
        guard startEngineIfNeeded() else {
            playUIKitFallback(intensity: intensity)
            return
        }

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
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
        playUIKitFallback(intensity: intensity)
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
                self.playSinglePulse(intensity: pulse.intensity, sharpness: pulse.sharpness)
                if pulse.includeUIKitOverlay {
                    self.playUIKitFallback(intensity: pulse.intensity)
                }
            }
        }
    }

    private func playUIKitFallback(intensity: Float) {
        DispatchQueue.main.async {
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            switch intensity {
            case ..<0.50:
                style = .heavy
            default:
                style = .rigid
            }
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)
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
    func playSliderTick() {}
    func pause() {}
    func resume(deficit: Double) {}
    func stopAll() {}
}
