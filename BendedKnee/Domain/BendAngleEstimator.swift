import CoreMotion
import Foundation

struct BendAngleEstimator {
    func rawAngleDegrees(gravity: CMAcceleration, pocketSide: PocketSide) -> Double {
        let normalized = normalizedGravity(gravity: gravity, pocketSide: pocketSide)
        let forward = max(normalized.z, 0)
        let vertical = max(-normalized.y, 0.0001)
        return atan2(forward, vertical) * 180.0 / .pi
    }

    func bendAngleDegrees(gravity: CMAcceleration, baselineAngle: Double, pocketSide: PocketSide) -> Double {
        max(0, rawAngleDegrees(gravity: gravity, pocketSide: pocketSide) - baselineAngle)
    }

    func isPlacementValid(gravity: CMAcceleration, pocketSide: PocketSide) -> Bool {
        let normalized = normalizedGravity(gravity: gravity, pocketSide: pocketSide)
        let isTopUp = normalized.y <= -0.2
        let screenFacesThigh = normalized.z >= -0.08
        let notTurnedSideways = abs(normalized.x) <= 0.82
        return isTopUp && screenFacesThigh && notTurnedSideways
    }

    private func normalizedGravity(gravity: CMAcceleration, pocketSide: PocketSide) -> CMAcceleration {
        CMAcceleration(
            x: gravity.x * pocketSide.lateralSign,
            y: gravity.y,
            z: gravity.z
        )
    }
}
