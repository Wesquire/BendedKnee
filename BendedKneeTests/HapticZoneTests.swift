import XCTest
@testable import BendedKnee

final class HapticZoneTests: XCTestCase {

    // MARK: - Zone Classification

    func testZone_negativeDeficit_returnsNone() {
        XCTAssertEqual(HapticZone.zone(for: -5), .none)
    }

    func testZone_zeroDeficit_returnsNone() {
        XCTAssertEqual(HapticZone.zone(for: 0), .none)
    }

    func testZone_verySmallDeficit_returnsNone() {
        XCTAssertEqual(HapticZone.zone(for: 0.3), .none)
    }

    func testZone_justBelowHalf_returnsNone() {
        XCTAssertEqual(HapticZone.zone(for: 0.49), .none)
    }

    func testZone_halfDegree_returnsGentle() {
        XCTAssertEqual(HapticZone.zone(for: 0.5), .gentle)
    }

    func testZone_twoDeficit_returnsGentle() {
        XCTAssertEqual(HapticZone.zone(for: 2), .gentle)
    }

    func testZone_fourPointNine_returnsGentle() {
        XCTAssertEqual(HapticZone.zone(for: 4.99), .gentle)
    }

    func testZone_fiveDeficit_returnsMedium() {
        XCTAssertEqual(HapticZone.zone(for: 5), .medium)
    }

    func testZone_tenDeficit_returnsMedium() {
        XCTAssertEqual(HapticZone.zone(for: 10), .medium)
    }

    func testZone_elevenPointNine_returnsMedium() {
        XCTAssertEqual(HapticZone.zone(for: 11.99), .medium)
    }

    func testZone_twelveDeficit_returnsStrong() {
        XCTAssertEqual(HapticZone.zone(for: 12), .strong)
    }

    func testZone_fiftyDeficit_returnsStrong() {
        XCTAssertEqual(HapticZone.zone(for: 50), .strong)
    }

    // MARK: - Zone Properties

    func testNoneZone_hasZeroIntensity() {
        XCTAssertEqual(HapticZone.none.intensity, 0.0)
    }

    func testIntensity_increasesWithZone() {
        XCTAssertLessThan(HapticZone.none.intensity, HapticZone.gentle.intensity)
        XCTAssertLessThan(HapticZone.gentle.intensity, HapticZone.medium.intensity)
        XCTAssertLessThan(HapticZone.medium.intensity, HapticZone.strong.intensity)
    }

    func testSharpness_increasesWithZone() {
        XCTAssertLessThan(HapticZone.none.sharpness, HapticZone.gentle.sharpness)
        XCTAssertLessThan(HapticZone.gentle.sharpness, HapticZone.medium.sharpness)
        XCTAssertLessThan(HapticZone.medium.sharpness, HapticZone.strong.sharpness)
    }

    func testInterval_decreasesWithZone() {
        XCTAssertGreaterThan(HapticZone.gentle.interval, HapticZone.medium.interval)
        XCTAssertGreaterThan(HapticZone.medium.interval, HapticZone.strong.interval)
    }

    func testStrongZone_intensitySubtle() {
        XCTAssertLessThanOrEqual(HapticZone.strong.intensity, 0.5)
    }

    func testStrongZone_sharpnessSubtle() {
        XCTAssertLessThanOrEqual(HapticZone.strong.sharpness, 0.5)
    }

    // MARK: - Labels

    func testLabels_areNotEmpty() {
        XCTAssertFalse(HapticZone.none.label.isEmpty)
        XCTAssertFalse(HapticZone.gentle.label.isEmpty)
        XCTAssertFalse(HapticZone.medium.label.isEmpty)
        XCTAssertFalse(HapticZone.strong.label.isEmpty)
    }

    // MARK: - Equatable

    func testEquatable() {
        XCTAssertEqual(HapticZone.none, HapticZone.none)
        XCTAssertEqual(HapticZone.gentle, HapticZone.gentle)
        XCTAssertNotEqual(HapticZone.none, HapticZone.gentle)
        XCTAssertNotEqual(HapticZone.medium, HapticZone.strong)
    }
}
