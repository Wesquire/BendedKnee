import CoreMotion
import XCTest
@testable import BendedKnee

final class AngleCalculatorTests: XCTestCase {

    // MARK: - BendAngleEstimator Extended Tests

    let estimator = BendAngleEstimator()

    func testRawAngle_uprightIsZero() {
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity), 0, accuracy: 0.01)
    }

    func testRawAngle_45DegreeTilt() {
        let gravity = CMAcceleration(x: 0, y: -sqrt(0.5), z: sqrt(0.5))
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity), 45, accuracy: 0.01)
    }

    func testRawAngle_90DegreeTilt() {
        let gravity = CMAcceleration(x: 0, y: -0.001, z: 1)
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity), 89.94, accuracy: 0.1)
    }

    func testRawAngle_30DegreeTilt() {
        let cos30 = cos(30.0 * .pi / 180.0)
        let sin30 = sin(30.0 * .pi / 180.0)
        let gravity = CMAcceleration(x: 0, y: -cos30, z: sin30)
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity), 30, accuracy: 0.01)
    }

    func testRawAngle_smallTilt() {
        let cos5 = cos(5.0 * .pi / 180.0)
        let sin5 = sin(5.0 * .pi / 180.0)
        let gravity = CMAcceleration(x: 0, y: -cos5, z: sin5)
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity), 5, accuracy: 0.01)
    }

    func testBendAngle_subtractsBaseline() {
        let cos30 = cos(30.0 * .pi / 180.0)
        let sin30 = sin(30.0 * .pi / 180.0)
        let gravity = CMAcceleration(x: 0, y: -cos30, z: sin30)
        XCTAssertEqual(estimator.bendAngleDegrees(gravity: gravity, baselineAngle: 5), 25, accuracy: 0.01)
    }

    func testBendAngle_clampsToZero() {
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.bendAngleDegrees(gravity: gravity, baselineAngle: 10), 0, accuracy: 0.01)
    }

    func testBendAngle_withNonZeroXComponent() {
        // Phone might have slight lateral tilt
        let gravity = CMAcceleration(x: 0.1, y: -0.9, z: 0.3)
        let angle = estimator.rawAngleDegrees(gravity: gravity)
        XCTAssertGreaterThan(angle, 0)
    }

    func testBendAngle_negativaZGravity() {
        // abs(z) is used, so negative z should give same result
        let gravity1 = CMAcceleration(x: 0, y: -0.866, z: 0.5)
        let gravity2 = CMAcceleration(x: 0, y: -0.866, z: -0.5)
        XCTAssertEqual(
            estimator.rawAngleDegrees(gravity: gravity1),
            estimator.rawAngleDegrees(gravity: gravity2),
            accuracy: 0.01
        )
    }
}
