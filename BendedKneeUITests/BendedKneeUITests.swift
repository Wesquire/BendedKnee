import XCTest

final class BendedKneeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsCalibrationControls() {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING", "FAST_CALIBRATION"]
        app.launch()

        advanceOnboarding(in: app)
        XCTAssertTrue(app.buttons["calibrateButton"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.sliders["targetSlider"].exists)
    }

    func testCalibrationEnablesSessionStart() {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING", "FAST_CALIBRATION"]
        app.launch()

        advanceOnboarding(in: app)
        app.buttons["calibrateButton"].tap()
        XCTAssertTrue(app.buttons["startSessionButton"].waitForExistence(timeout: 2))
    }

    func testSessionCanStartAndEnd() {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING", "FAST_CALIBRATION"]
        app.launch()

        advanceOnboarding(in: app)
        app.buttons["calibrateButton"].tap()
        app.buttons["startSessionButton"].tap()

        XCTAssertTrue(app.staticTexts["sessionAngleText"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["endSessionButton"].exists)

        app.buttons["endSessionButton"].tap()

        XCTAssertTrue(app.buttons["calibrateButton"].waitForExistence(timeout: 2))
    }

    func testFirstLaunchStartsInFullScreenOnboarding() {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING", "FAST_CALIBRATION"]
        app.launch()

        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["calibrateButton"].exists)
    }

    func testCalibrationFailureShowsHelpfulMessage() {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING", "FAST_CALIBRATION", "NOISY_CALIBRATION"]
        app.launch()

        advanceOnboarding(in: app)
        app.buttons["calibrateButton"].tap()

        XCTAssertTrue(app.staticTexts["Calibration failed. Hold still and keep the phone settled."].waitForExistence(timeout: 5))
    }

    func testUnavailableMotionShowsUnavailableState() {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING", "FAST_CALIBRATION", "UNAVAILABLE_MOTION"]
        app.launch()

        advanceOnboarding(in: app)
        XCTAssertTrue(app.staticTexts["Motion data is unavailable."].waitForExistence(timeout: 2))
    }

    func testPocketRemovalShowsPausedSessionState() {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING", "FAST_CALIBRATION", "AUTO_REMOVE_PROXIMITY"]
        app.launch()

        advanceOnboarding(in: app)
        app.buttons["calibrateButton"].tap()
        app.buttons["startSessionButton"].tap()

        XCTAssertTrue(app.staticTexts["Phone Removed"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.otherElements["sessionStateBadge"].exists)
    }

    private func advanceOnboarding(in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
        app.buttons["onboardingNextButton"].tap()
        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
        app.buttons["onboardingNextButton"].tap()
        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
        app.buttons["onboardingNextButton"].tap()
        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 2))
        app.buttons["continueButton"].tap()
    }
}
