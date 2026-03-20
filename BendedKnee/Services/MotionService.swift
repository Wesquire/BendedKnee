import CoreMotion
import Foundation

struct MotionSnapshot {
    let gravity: CMAcceleration
    let timestamp: TimeInterval
}

protocol MotionServiceProtocol {
    var isAvailable: Bool { get }
    func start(handler: @escaping (MotionSnapshot) -> Void)
    func stop()
}

final class DeviceMotionService: MotionServiceProtocol {
    private let manager = CMMotionManager()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "BendedKnee.DeviceMotion"
        queue.qualityOfService = .userInteractive
        return queue
    }()

    var isAvailable: Bool {
        manager.isDeviceMotionAvailable
    }

    func start(handler: @escaping (MotionSnapshot) -> Void) {
        guard isAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: queue) { motion, _ in
            guard let motion else { return }
            let snapshot = MotionSnapshot(gravity: motion.gravity, timestamp: motion.timestamp)
            DispatchQueue.main.async {
                handler(snapshot)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

final class PreviewMotionService: MotionServiceProtocol {
    enum Mode {
        case steadySkate
        case noisyCalibration
        case unavailable
    }

    private let mode: Mode
    private let queue = DispatchQueue(label: "BendedKnee.PreviewMotion")
    private var timer: DispatchSourceTimer?
    private var tick: Double = 0

    init(mode: Mode = .steadySkate) {
        self.mode = mode
    }

    var isAvailable: Bool { mode != .unavailable }

    func start(handler: @escaping (MotionSnapshot) -> Void) {
        guard isAvailable else { return }
        guard timer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            tick += 0.1

            let angle: Double
            switch mode {
            case .steadySkate:
                angle = 6.0 + sin(tick) * 0.25
            case .noisyCalibration:
                let samples = [4.0, 12.0, 2.0, 11.0, 3.0, 10.0]
                angle = samples[Int((tick * 10).rounded()) % samples.count]
            case .unavailable:
                return
            }

            let radians = angle * .pi / 180
            let gravity = CMAcceleration(x: 0, y: -cos(radians), z: sin(radians))
            let snapshot = MotionSnapshot(gravity: gravity, timestamp: tick)
            DispatchQueue.main.async {
                handler(snapshot)
            }
        }
        self.timer = timer
        timer.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
}
