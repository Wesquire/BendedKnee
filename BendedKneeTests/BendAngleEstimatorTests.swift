import CoreMotion
import XCTest
@testable import BendedKnee

final class BendAngleEstimatorTests: XCTestCase {
    func testRawAngleIsZeroWhenUpright() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity), 0, accuracy: 0.001)
    }

    func testRawAngleMatchesForwardTilt() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -sqrt(0.5), z: sqrt(0.5))
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity), 45, accuracy: 0.001)
    }

    func testBaselineSubtractionClampsAtZero() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.bendAngleDegrees(gravity: gravity, baselineAngle: 10), 0, accuracy: 0.001)
    }
}
