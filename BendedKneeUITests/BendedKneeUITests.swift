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
        XCTAssertTrue(app.switches["hapticsToggle"].exists)
        XCTAssertTrue(app.sliders["volumeSlider"].exists)
    }

    func testCalibrationEnablesSessionStart() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"], in: app)
        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        waitForButtonToBecomeEnabled(startButton)
    }

    func testSessionShowsStopControlAfterStart() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"], in: app)
        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        waitForButtonToBecomeEnabled(startButton)
        tap(startButton, in: app)

        XCTAssertTrue(app.staticTexts["sessionAngleText"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["endSessionButton"].exists)
    }

    func testSetupExposesHapticsAndAudioControls() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        XCTAssertTrue(app.switches["hapticsToggle"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["testSoundButton"].waitForExistence(timeout: 2))
    }

    func testSkatingSetupDisclosureRevealsPlacementGuidance() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        advanceOnboarding(in: app)
        let disclosure = app.buttons["skatingSetupDisclosure"]
        XCTAssertTrue(disclosure.waitForExistence(timeout: 2))

        let placementHeading = app.staticTexts["Placement"]
        if !placementHeading.exists {
            tap(disclosure, in: app)
        }

        XCTAssertTrue(placementHeading.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Keep the phone top-up.'")).firstMatch.exists)
    }

    func testFirstLaunchStartsInFullScreenOnboarding() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION"])

        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["calibrateButton"].exists)
    }

    func testSplashAppearsWhenRequestedInUITests() {
        let app = launchApp(arguments: ["UITESTING", "SHOW_SPLASH", "FAST_CALIBRATION"])

        XCTAssertFalse(app.buttons["onboardingNextButton"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["onboardingNextButton"].waitForExistence(timeout: 8))
    }

    func testCalibrationFailureShowsHelpfulMessage() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION", "NOISY_CALIBRATION"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"], in: app)

        XCTAssertTrue(app.staticTexts["Calibration failed. Put the phone in your left front pocket, let it settle, and try again."].waitForExistence(timeout: 5))
    }

    func testUnavailableMotionShowsUnavailableState() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION", "UNAVAILABLE_MOTION"])

        advanceOnboarding(in: app)
        XCTAssertTrue(app.staticTexts["Motion data is unavailable."].waitForExistence(timeout: 2))
    }

    func testPocketRemovalShowsPausedState() {
        let app = launchApp(arguments: ["UITESTING", "FAST_CALIBRATION", "AUTO_REMOVE_PROXIMITY"])

        advanceOnboarding(in: app)
        tap(app.buttons["calibrateButton"], in: app)
        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        waitForButtonToBecomeEnabled(startButton)
        tap(startButton, in: app)

        XCTAssertTrue(app.staticTexts["Phone Removed"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["Return the phone to your front pocket to resume haptic coaching."].exists)
    }

    func testReturningUserSeesWelcomeBackScreen() {
        let app = launchApp(arguments: ["UITESTING", "RETURNING_USER"])

        XCTAssertTrue(app.buttons["welcomeBackContinueButton"].waitForExistence(timeout: 2))
        tap(app.buttons["welcomeBackContinueButton"], in: app)
        XCTAssertTrue(app.buttons["calibrateButton"].waitForExistence(timeout: 2))
    }

    private func advanceOnboarding(in app: XCUIApplication) {
        for _ in 0..<6 {
            let continueButton = app.buttons["continueButton"]
            if continueButton.waitForExistence(timeout: 2) {
                tap(continueButton, in: app)
                return
            }

            let nextButton = app.buttons["onboardingNextButton"]
            XCTAssertTrue(nextButton.waitForExistence(timeout: 4))
            tap(nextButton, in: app)
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

    private func tap(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 4) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))

        let directTapIdentifiers: Set<String> = [
            "onboardingNextButton",
            "continueButton",
            "onboardingBackButton",
            "startSessionButton",
            "testSoundButton",
            "skatingSetupDisclosure",
            "welcomeBackContinueButton"
        ]
        if directTapIdentifiers.contains(element.identifier) {
            element.tap()
            return
        }

        let scrollContainer = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app

        for _ in 0..<8 {
            if element.isHittable {
                element.tap()
                return
            }
            scrollContainer.swipeUp()
        }

        let frame = element.frame
        if frame.width > 0, frame.height > 0 {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }

        XCTFail("Element never became hittable: \(element)")
    }

    private func waitForButtonToBecomeEnabled(_ button: XCUIElement) {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: button)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 4), .completed)
    }

}
