import XCTest

final class BendedKneeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsCalibrationControls() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        XCTAssertTrue(app.buttons["calibrateButton"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.sliders["targetSlider"].exists)
        XCTAssertTrue(app.segmentedControls["pocketSidePicker"].exists)
    }

    func testCalibrationEnablesSessionStart() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"])
        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        waitForButtonToBecomeEnabled(startButton)
    }

    func testSessionShowsStopControlAfterStart() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"])
        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        waitForButtonToBecomeEnabled(startButton)
        tap(startButton)

        XCTAssertTrue(app.staticTexts["sessionAngleText"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["endSessionButton"].exists)
    }

    func testSetupExposesPocketAndSampleControls() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        XCTAssertTrue(app.segmentedControls["pocketSidePicker"].waitForExistence(timeout: 2))
        tap(app.buttons["Preview & Help"])
        XCTAssertTrue(app.buttons["samplePulseButton"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["reopenOnboardingButton"].exists)
    }

    func testSetupGuideCanBeReopenedFromSettings() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        tap(app.buttons["Preview & Help"])
        let reopenButton = app.buttons["reopenOnboardingButton"]
        XCTAssertTrue(reopenButton.waitForExistence(timeout: 2))
        tap(reopenButton)

        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
    }

    func testFirstLaunchStartsInFullScreenOnboarding() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["calibrateButton"].exists)
    }

    func testSplashAppearsWhenRequestedInUITests() {
        let app = launchApp(arguments: ["UITESTING", "SHOW_SPLASH", "FAST_SPLASH", "FAST_CALIBRATION"])

        XCTAssertTrue(app.otherElements["splashView"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 3))
    }

    func testCalibrationFailureShowsHelpfulMessage() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION", "NOISY_CALIBRATION"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"])

        XCTAssertTrue(app.staticTexts["Calibration failed. Hold still and keep the phone settled."].waitForExistence(timeout: 5))
    }

    func testUnavailableMotionShowsUnavailableState() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION", "UNAVAILABLE_MOTION"])

        advanceOnboarding(in: app)
        XCTAssertTrue(app.staticTexts["Motion data is unavailable."].waitForExistence(timeout: 2))
    }

    func testPocketRemovalShowsPausedState() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION", "AUTO_REMOVE_PROXIMITY"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"])
        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        waitForButtonToBecomeEnabled(startButton)
        tap(startButton)

        XCTAssertTrue(app.staticTexts["Phone Removed"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["Return the phone to your front pocket to resume haptic coaching."].exists)
    }

    func testPocketSideCanBeSelectedDuringSetup() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        let picker = app.segmentedControls["pocketSidePicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        tap(picker.buttons["Left"])
        XCTAssertTrue(app.staticTexts["Use your left front pocket."].waitForExistence(timeout: 2))
    }

    private func advanceOnboarding(in app: XCUIApplication) {
        for _ in 0..<6 {
            let continueButton = app.buttons["continueButton"]
            if continueButton.waitForExistence(timeout: 1) {
                tap(continueButton)
                return
            }

            let nextButton = app.buttons["onboardingNextButton"]
            XCTAssertTrue(nextButton.waitForExistence(timeout: 2))
            tap(nextButton)
        }

        XCTFail("Onboarding did not reach the final continue button.")
    }

    private func launchApp(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launch()
        return app
    }

    private func tap(_ element: XCUIElement, timeout: TimeInterval = 4) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))

        let predicate = NSPredicate(format: "hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        _ = XCTWaiter().wait(for: [expectation], timeout: timeout)

        for _ in 0..<3 {
            if element.isHittable {
                element.tap()
                return
            }
            XCUIApplication().swipeUp()
        }

        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func waitForButtonToBecomeEnabled(_ button: XCUIElement) {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: button)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 4), .completed)
    }
}
