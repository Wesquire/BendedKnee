import CoreHaptics
import Foundation

protocol HapticsControlling {
    func start()
    func update(deficit: Double)
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

    func stopAll() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        currentZone = .none
        try? engine?.stop()
    }

    private func playPulse(for zone: HapticZone) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        start()

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: zone.intensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: zone.sharpness)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
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
    func stopAll() {}
}
