import CoreHaptics
import Foundation

protocol HapticsControlling {
    func start()
    func update(deficit: Double)
    func playSamplePulse()
    func stopAll()
}

final class HapticsService: HapticsControlling {
    private var engine: CHHapticEngine?
    private var pulseTimer: Timer?
    private var currentZone: HapticZone = .none

    func start() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        if engine == nil {
            engine = try? CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
        }

        try? engine?.start()
    }

    func update(deficit: Double) {
        let zone = HapticZone.zone(for: deficit)
        guard zone != currentZone else { return }
        currentZone = zone

        pulseTimer?.invalidate()
        pulseTimer = nil

        guard zone != .none else { return }

        playPulse(for: zone)
        pulseTimer = Timer.scheduledTimer(withTimeInterval: zone.interval, repeats: true) { [weak self] _ in
            self?.playPulse(for: zone)
        }
    }

    func playSamplePulse() {
        playSamplePulse(intensity: 0.24, sharpness: 0.10)
    }

    func stopAll() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        currentZone = .none
        try? engine?.stop()
    }

    private func playPulse(for zone: HapticZone) {
        playSamplePulse(intensity: zone.intensity, sharpness: zone.sharpness)
    }

    private func playSamplePulse(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        start()

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
            return
        }

        try? player.start(atTime: 0)
    }
}

final class NoOpHapticsService: HapticsControlling {
    func start() {}
    func update(deficit: Double) {}
    func playSamplePulse() {}
    func stopAll() {}
}
