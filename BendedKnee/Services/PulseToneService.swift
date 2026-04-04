import AVFoundation
import Foundation

protocol PulseToneControlling {
    func playPulseTone(zone: HapticZone, volume: Float)
    func playTestTone(volume: Float)
    func playCalibrationStartTone(volume: Float)
    func playCalibrationSuccessTone(volume: Float)
    func playCalibrationFailureTone(volume: Float)
    func startKeepAlive()
    func stopKeepAlive()
    func stop()
}

final class PulseToneService: PulseToneControlling {
    private var player: AVAudioPlayer?
    private var keepAlivePlayer: AVAudioPlayer?
    private var keepAliveTimer: Timer?
    private var interruptionObserver: NSObjectProtocol?

    init() {
        configureAudioSession()
        observeInterruptions()
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    // Pentatonic notes — all from C major chord, sound good in any order
    private static let gentleFreq: Double = 523.25  // C5
    private static let mediumFreq: Double = 659.25  // E5
    private static let strongFreq: Double = 783.99  // G5

    func playPulseTone(zone: HapticZone, volume: Float) {
        guard volume > 0, zone != .none else { return }
        switch zone {
        case .none:
            return
        case .gentle:
            playTone(frequency: Self.gentleFreq, duration: 0.10, volume: volume)
        case .medium:
            playTone(frequency: Self.mediumFreq, duration: 0.12, volume: volume)
        case .strong:
            playTone(frequency: Self.strongFreq, duration: 0.14, volume: volume)
        }
    }

    func playTestTone(volume: Float) {
        guard volume > 0 else { return }
        // Play gentle → medium → strong in quick succession so user hears the musical relationship
        playTone(frequency: Self.gentleFreq, duration: 0.10, volume: volume)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
            self?.playTone(frequency: Self.mediumFreq, duration: 0.12, volume: volume)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) { [weak self] in
            self?.playTone(frequency: Self.strongFreq, duration: 0.14, volume: volume)
        }
    }

    func playCalibrationStartTone(volume: Float) {
        guard volume > 0 else { return }
        // Single warm note — capture has begun
        playTone(frequency: Self.gentleFreq, duration: 0.18, volume: volume)
    }

    func playCalibrationSuccessTone(volume: Float) {
        guard volume > 0 else { return }
        // Rising perfect fifth (C5 → G5) — sounds like arrival
        playTone(frequency: Self.gentleFreq, duration: 0.14, volume: volume)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { [weak self] in
            self?.playTone(frequency: Self.strongFreq, duration: 0.18, volume: volume)
        }
    }

    func playCalibrationFailureTone(volume: Float) {
        guard volume > 0 else { return }
        // Descending minor second (E5 → Eb5) — gentle disappointment
        playTone(frequency: Self.mediumFreq, duration: 0.12, volume: volume)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.playTone(frequency: 622.25, duration: 0.14, volume: volume) // Eb5
        }
    }

    func startKeepAlive() {
        guard keepAliveTimer == nil else { return }
        playKeepAlivePulse()
        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.playKeepAlivePulse()
        }
        keepAliveTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        keepAlivePlayer?.stop()
        keepAlivePlayer = nil
    }

    func stop() {
        player?.stop()
        player = nil
        stopKeepAlive()
    }

    private func playKeepAlivePulse() {
        let sampleRate: Double = 44100
        let duration: Double = 0.5
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            samples[i] = Float(sin(2.0 * .pi * 440.0 * t))
        }
        guard let data = wavData(samples: samples, sampleRate: Int(sampleRate)) else { return }
        do {
            let newPlayer = try AVAudioPlayer(data: data)
            newPlayer.volume = 0.001
            newPlayer.prepareToPlay()
            newPlayer.play()
            keepAlivePlayer = newPlayer
        } catch {}
    }

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        let sampleRate: Double = 44100
        let sampleCount = Int(sampleRate * duration)
        let attackSamples = Int(sampleRate * 0.005) // 5ms soft attack
        let decayStart = Int(Double(sampleCount) * 0.3) // decay begins at 30% of duration

        var samples = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            // Fundamental + soft second harmonic for warmth
            var sample = Float(sin(2.0 * .pi * frequency * t) * 0.85 + sin(2.0 * .pi * frequency * 2.0 * t) * 0.15)

            // Soft attack (5ms fade in)
            if i < attackSamples {
                let attackProgress = Double(i) / Double(attackSamples)
                sample *= Float(attackProgress * attackProgress) // quadratic ease-in
            }
            // Exponential decay after 30%
            if i >= decayStart {
                let decayProgress = Double(i - decayStart) / Double(sampleCount - decayStart)
                sample *= Float(exp(-3.0 * decayProgress)) // natural exponential decay
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

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .ended {
                try? AVAudioSession.sharedInstance().setActive(true)
                if self?.keepAliveTimer != nil {
                    self?.playKeepAlivePulse()
                }
            }
        }
    }
}

final class NoOpPulseToneService: PulseToneControlling {
    func playPulseTone(zone: HapticZone, volume: Float) {}
    func playTestTone(volume: Float) {}
    func playCalibrationStartTone(volume: Float) {}
    func playCalibrationSuccessTone(volume: Float) {}
    func playCalibrationFailureTone(volume: Float) {}
    func startKeepAlive() {}
    func stopKeepAlive() {}
    func stop() {}
}
