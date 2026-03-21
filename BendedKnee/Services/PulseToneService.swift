import AVFoundation
import Foundation

protocol PulseToneControlling {
    func playPulseTone(zone: HapticZone, volume: Float)
    func playTestTone(volume: Float)
    func stop()
}

final class PulseToneService: PulseToneControlling {
    private var player: AVAudioPlayer?

    init() {
        configureAudioSession()
    }

    func playPulseTone(zone: HapticZone, volume: Float) {
        guard volume > 0, zone != .none else { return }
        let frequency: Double
        let duration: Double
        switch zone {
        case .none:
            return
        case .gentle:
            frequency = 520   // soft mid-tone
            duration = 0.08
        case .medium:
            frequency = 680   // higher urgency
            duration = 0.10
        case .strong:
            frequency = 880   // sharp high alert
            duration = 0.12
        }
        playTone(frequency: frequency, duration: duration, volume: volume)
    }

    func playTestTone(volume: Float) {
        guard volume > 0 else { return }
        playTone(frequency: 680, duration: 0.15, volume: volume)
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        let sampleRate: Double = 44100
        let sampleCount = Int(sampleRate * duration)
        let fadeOutSamples = min(sampleCount / 4, Int(sampleRate * 0.02))

        var samples = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            var sample = Float(sin(2.0 * .pi * frequency * t))

            // Fade in first 1ms
            let fadeInSamples = min(44, sampleCount)
            if i < fadeInSamples {
                sample *= Float(i) / Float(fadeInSamples)
            }
            // Fade out
            let fadeStart = sampleCount - fadeOutSamples
            if i >= fadeStart {
                sample *= Float(sampleCount - i) / Float(fadeOutSamples)
            }

            samples[i] = sample
        }

        guard let data = wavData(samples: samples, sampleRate: Int(sampleRate)) else { return }

        do {
            let newPlayer = try AVAudioPlayer(data: data)
            newPlayer.volume = min(max(volume, 0), 1)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
        } catch {
            // Silent failure — haptics still work
        }
    }

    private func wavData(samples: [Float], sampleRate: Int) -> Data? {
        let channels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(channels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(channels * bitsPerSample / 8)
        let dataSize = Int32(samples.count * Int(blockAlign))
        let fileSize = 36 + dataSize

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) }) // PCM
        data.append(withUnsafeBytes(of: channels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        for sample in samples {
            let clamped = min(max(sample, -1), 1)
            let intSample = Int16(clamped * Float(Int16.max))
            data.append(withUnsafeBytes(of: intSample.littleEndian) { Data($0) })
        }

        return data
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Silent — audio is supplementary
        }
    }
}

final class NoOpPulseToneService: PulseToneControlling {
    func playPulseTone(zone: HapticZone, volume: Float) {}
    func playTestTone(volume: Float) {}
    func stop() {}
}
