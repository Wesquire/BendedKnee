import XCTest
@testable import BendedKnee

final class CalibrationAccumulatorTests: XCTestCase {
    func testAverageIsNilWithoutSamples() {
        XCTAssertNil(CalibrationAccumulator().average)
    }

    func testAverageUsesAllSamples() {
        var accumulator = CalibrationAccumulator()
        accumulator.add(10)
        accumulator.add(16)
        accumulator.add(20)
        XCTAssertNotNil(accumulator.average)
        XCTAssertEqual(accumulator.average ?? 0, 46.0 / 3.0, accuracy: 0.001)
    }

    func testSpreadTracksDistanceBetweenMinAndMax() {
        var accumulator = CalibrationAccumulator()
        accumulator.add(10)
        accumulator.add(13)
        accumulator.add(19)
        XCTAssertEqual(accumulator.spread ?? 0, 9, accuracy: 0.001)
    }

    func testIsStableUsesSpreadThreshold() {
        var accumulator = CalibrationAccumulator()
        accumulator.add(10)
        accumulator.add(10.8)
        accumulator.add(11.2)
        XCTAssertTrue(accumulator.isStable(minimumSamples: 3, maximumSpread: 2))
        XCTAssertFalse(accumulator.isStable(minimumSamples: 4, maximumSpread: 2))
        XCTAssertFalse(accumulator.isStable(minimumSamples: 3, maximumSpread: 0.5))
    }
}
