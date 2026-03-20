import CoreMotion
import XCTest
@testable import BendedKnee

final class BendAngleEstimatorTests: XCTestCase {
    func testRawAngleIsZeroWhenUpright() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity, pocketSide: .right), 0, accuracy: 0.001)
    }

    func testRawAngleMatchesForwardTilt() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -sqrt(0.5), z: sqrt(0.5))
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity, pocketSide: .right), 45, accuracy: 0.001)
    }

    func testBaselineSubtractionClampsAtZero() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.bendAngleDegrees(gravity: gravity, baselineAngle: 10, pocketSide: .right), 0, accuracy: 0.001)
    }

    func testPlacementValidationRejectsUpsideDownOrientation() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: 0.9, z: 0.1)
        XCTAssertFalse(estimator.isPlacementValid(gravity: gravity, pocketSide: .right))
    }

    func testPlacementValidationRejectsScreenAwayOrientation() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -0.86, z: -0.3)
        XCTAssertFalse(estimator.isPlacementValid(gravity: gravity, pocketSide: .right))
    }

    func testMirroredPocketsProduceSameForwardAngle() {
        let estimator = BendAngleEstimator()
        let leftPocketGravity = CMAcceleration(x: -0.18, y: -0.92, z: 0.31)
        let rightPocketGravity = CMAcceleration(x: 0.18, y: -0.92, z: 0.31)

        XCTAssertEqual(
            estimator.rawAngleDegrees(gravity: leftPocketGravity, pocketSide: .left),
            estimator.rawAngleDegrees(gravity: rightPocketGravity, pocketSide: .right),
            accuracy: 0.001
        )
    }

    func testPlacementValidationMirrorsAcrossPocketSides() {
        let estimator = BendAngleEstimator()
        let leftPocketGravity = CMAcceleration(x: -0.20, y: -0.95, z: 0.18)
        let rightPocketGravity = CMAcceleration(x: 0.20, y: -0.95, z: 0.18)

        XCTAssertTrue(estimator.isPlacementValid(gravity: leftPocketGravity, pocketSide: .left))
        XCTAssertTrue(estimator.isPlacementValid(gravity: rightPocketGravity, pocketSide: .right))
    }
}
