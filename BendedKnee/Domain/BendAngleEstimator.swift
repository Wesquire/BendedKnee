import CoreMotion
import Foundation

struct BendAngleEstimator {
    func rawAngleDegrees(gravity: CMAcceleration) -> Double {
        let forward = abs(gravity.z)
        let vertical = max(abs(gravity.y), 0.0001)
        return atan2(forward, vertical) * 180.0 / .pi
    }

    func bendAngleDegrees(gravity: CMAcceleration, baselineAngle: Double) -> Double {
        max(0, rawAngleDegrees(gravity: gravity) - baselineAngle)
    }
}
