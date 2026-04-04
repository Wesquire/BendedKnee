import CoreMotion
import XCTest
@testable import BendedKnee

final class BendAngleEstimatorTests: XCTestCase {
    func testRawAngleIsZeroWhenUpright() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity, pocketSide: .frontRight), 0, accuracy: 0.001)
    }

    func testRawAngleMatchesForwardTilt() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -sqrt(0.5), z: sqrt(0.5))
        XCTAssertEqual(estimator.rawAngleDegrees(gravity: gravity, pocketSide: .frontRight), 45, accuracy: 0.001)
    }

    func testBaselineSubtractionClampsAtZero() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -1, z: 0)
        XCTAssertEqual(estimator.bendAngleDegrees(gravity: gravity, baselineAngle: 10, pocketSide: .frontRight), 0, accuracy: 0.001)
    }

    func testPlacementValidationRejectsUpsideDownOrientation() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: 0.9, z: 0.1)
        XCTAssertFalse(estimator.isPlacementValid(gravity: gravity, pocketSide: .frontRight))
    }

    func testPlacementValidationRejectsScreenAwayOrientation() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -0.86, z: -0.3)
        XCTAssertFalse(estimator.isPlacementValid(gravity: gravity, pocketSide: .frontRight))
    }

    func testMirroredPocketsProduceSameForwardAngle() {
        let estimator = BendAngleEstimator()
        let leftPocketGravity = CMAcceleration(x: -0.18, y: -0.92, z: 0.31)
        let rightPocketGravity = CMAcceleration(x: 0.18, y: -0.92, z: 0.31)

        XCTAssertEqual(
            estimator.rawAngleDegrees(gravity: leftPocketGravity, pocketSide: .frontLeft),
            estimator.rawAngleDegrees(gravity: rightPocketGravity, pocketSide: .frontRight),
            accuracy: 0.001
        )
    }

    func testPlacementValidationMirrorsAcrossPocketSides() {
        let estimator = BendAngleEstimator()
        let leftPocketGravity = CMAcceleration(x: -0.20, y: -0.95, z: 0.18)
        let rightPocketGravity = CMAcceleration(x: 0.20, y: -0.95, z: 0.18)

        XCTAssertTrue(estimator.isPlacementValid(gravity: leftPocketGravity, pocketSide: .frontLeft))
        XCTAssertTrue(estimator.isPlacementValid(gravity: rightPocketGravity, pocketSide: .frontRight))
    }

    func testBackPocketProducesSameAngleAsEquivalentFrontPocket() {
        let estimator = BendAngleEstimator()
        // Back pocket: screen faces away, so Z is negative when bending forward
        let backPocketGravity = CMAcceleration(x: 0.18, y: -0.92, z: -0.31)
        let frontPocketGravity = CMAcceleration(x: 0.18, y: -0.92, z: 0.31)

        XCTAssertEqual(
            estimator.rawAngleDegrees(gravity: backPocketGravity, pocketSide: .backLeft),
            estimator.rawAngleDegrees(gravity: frontPocketGravity, pocketSide: .frontRight),
            accuracy: 0.001
        )
    }

    func testBackPocketPlacementValidationAcceptsNegativeZ() {
        let estimator = BendAngleEstimator()
        // In back pocket, screen faces away: raw Z is negative but depthSign flips it
        let gravity = CMAcceleration(x: 0.20, y: -0.95, z: -0.18)
        XCTAssertTrue(estimator.isPlacementValid(gravity: gravity, pocketSide: .backRight))
    }

    func testFrontPocketRejectsNegativeZPlacement() {
        let estimator = BendAngleEstimator()
        let gravity = CMAcceleration(x: 0, y: -0.86, z: -0.3)
        XCTAssertFalse(estimator.isPlacementValid(gravity: gravity, pocketSide: .frontRight))
    }

    func testAllFourPocketsProduceConsistentAngles() {
        let estimator = BendAngleEstimator()
        let angle45 = 45.0 * .pi / 180.0

        // Front left: x negative, z positive
        let fl = CMAcceleration(x: -0.1, y: -cos(angle45), z: sin(angle45))
        // Front right: x positive, z positive
        let fr = CMAcceleration(x: 0.1, y: -cos(angle45), z: sin(angle45))
        // Back left: x positive, z negative (rotated 180° around Y)
        let bl = CMAcceleration(x: 0.1, y: -cos(angle45), z: -sin(angle45))
        // Back right: x negative, z negative
        let br = CMAcceleration(x: -0.1, y: -cos(angle45), z: -sin(angle45))

        let flAngle = estimator.rawAngleDegrees(gravity: fl, pocketSide: .frontLeft)
        let frAngle = estimator.rawAngleDegrees(gravity: fr, pocketSide: .frontRight)
        let blAngle = estimator.rawAngleDegrees(gravity: bl, pocketSide: .backLeft)
        let brAngle = estimator.rawAngleDegrees(gravity: br, pocketSide: .backRight)

        XCTAssertEqual(flAngle, frAngle, accuracy: 0.001)
        XCTAssertEqual(flAngle, blAngle, accuracy: 0.001)
        XCTAssertEqual(flAngle, brAngle, accuracy: 0.001)
    }
}
