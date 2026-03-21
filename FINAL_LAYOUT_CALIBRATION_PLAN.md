# Final Layout And Calibration Plan

## Objective

Close the remaining product-quality gaps in Bended Knee by fixing aspect-ratio behavior, onboarding clarity, setup structure, calibration trust, retro visual identity, and full validation.

## Sequenced Todo List

### Phase 1 - Launch, Layout, And Onboarding Foundation

- [ ] Audit the current launch and onboarding flow against the requested first-run-only behavior.
- [ ] Fix onboarding so it occupies the full screen on iPhone 16 Pro-class aspect ratios.
- [ ] Rebuild onboarding copy hierarchy so explanatory text is visible and not compressed near the bottom.
- [ ] Remove the redundant upper-right final-page status text.
- [ ] Ensure the last onboarding CTA exits cleanly into the main app.
- [ ] Preserve first-run-only onboarding behavior so later launches go directly to the main screen.

### Phase 2 - Setup Screen Information Architecture

- [ ] Remove redundant setup examples from the always-visible summary area.
- [ ] Convert `Skating Setup` into a disclosure section that defaults to collapsed.
- [ ] Move placement guidance directly under the `Skating Setup` disclosure.
- [ ] Remove the `Review Setup Guide` button.
- [ ] Keep setup controls honest about what is and is not completed.
- [ ] Repair the sample haptic button so it produces a perceivable response in app use.

### Phase 3 - Calibration Trust Rebuild

- [ ] Replace the current immediate calibration start with an explicit 4-second prep countdown.
- [ ] Add a separate 4-second calibration capture phase after the prep countdown.
- [ ] Keep total calibration timeline within the approved 10-second maximum.
- [ ] Add one haptic when the actual capture begins.
- [ ] Add two haptics on successful completion.
- [ ] Add three haptics on calibration failure.
- [ ] Expose clear user-facing success/failure language and retry guidance.
- [ ] Clean up misleading placement messaging during the pre-pocket transition.

### Phase 4 - Retro Roller-Rink Visual Refresh

- [ ] Shift the palette toward warm 70s rink-poster tones.
- [ ] Propagate the palette through splash, onboarding, home, setup, and session surfaces.
- [ ] Adjust spacing, sizing, and safe-area usage so tall devices scale correctly.

### Phase 5 - Test Expansion And End-To-End Validation

- [ ] Add new unit coverage for calibration staging and calibration-result haptic signaling.
- [ ] Add new unit coverage for onboarding persistence and setup disclosure behavior where applicable.
- [ ] Add new UI coverage for first-run onboarding, final onboarding exit, setup disclosure flow, and revised calibration flow.
- [ ] Run the full unit suite until all tests pass.
- [ ] Run the full UI suite until all tests pass.
- [ ] Build and launch the app on simulator to confirm it runs successfully.
- [ ] Update validation and orchestration docs with exact completed work and exact executed commands.

## Acceptance Standard

The pass is only complete when:

- onboarding is full-screen and advances correctly
- returning users go directly to the main screen
- setup layout is simpler and logically ordered
- sample haptics work
- calibration uses the new prep-plus-capture flow with clear outcomes
- the visual system reads as warm retro roller-rink rather than generic earthy
- the app builds, tests, and launches successfully in Xcode/simulator verification
