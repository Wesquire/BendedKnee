# Phase 13 - Launch, Layout, Audio, and Setup Overhaul

## Objective

Implement the next product pass for `Drop` with these goals:

- eliminate the remaining iPhone 16 Pro layout failures
- add a `6` second cold-launch splash
- add a recurring welcome-back screen after onboarding is complete
- convert the product to left-pocket-only
- add a master haptics on/off control
- preserve and expand pulse audio so session coaching plus calibration cues use the same volume slider
- make calibration a truthful `7` second experience in both behavior and copy
- rebuild the home screen setup information architecture
- push the visual language much harder into bold 70s roller-rink poster styling
- document the work across the project tracking markdown files

## Itemized Checklist

### Phase 1 - Planning and Tracking

- [x] Review launch, home, settings, session, onboarding, and services code paths
- [x] Create this root plan file
- [x] Create a root evidence file under `tests/`
- [x] Append the new work scope to:
  - [x] `/Users/wesquire/Github/Bended Knee/PROGRESS_LOG.md`
  - [x] `/Users/wesquire/Github/Bended Knee/ORCHESTRATOR_REPORT.md`
  - [x] `/Users/wesquire/Github/Bended Knee/APP_FEATURES.md`
  - [x] `/Users/wesquire/Github/Bended Knee/FINAL_VALIDATION.md`

### Phase 2 - Launch Flow

- [x] Change production splash duration from `2.5` seconds to `6` seconds
- [x] Ensure the `6` second splash is cold-launch only
- [x] Add a welcome-back screen that appears every launch after onboarding is complete
- [x] Allow the user to dismiss the welcome-back screen explicitly
- [x] Keep UI-test launch behavior deterministic

### Phase 3 - Settings and Coaching Model

- [x] Remove right-pocket support from product settings and UI
- [x] Default all logic to left pocket only
- [x] Add a master `Haptics` on/off setting that disables:
  - [x] calibration haptics
  - [x] live session haptics
  - [x] slider tick haptics
- [x] Keep pulse audio and volume slider behavior
- [x] Remove the sample pulse feature and button
- [x] Remove the pocket-side picker and related copy
- [x] Keep volume `0` as effective audio off

### Phase 4 - Calibration Redesign

- [x] Make calibration total duration actually `7` seconds
- [x] Update all copy to truthfully describe the `7` second calibration
- [x] Add calibration audio completion behavior using the existing volume slider
- [x] Make calibration completion messaging mention confirmation sound/vibration
- [x] Review the CoreMotion console warning and suppress it if app-caused
- [x] If it is not app-caused, document the honest limitation and any mitigation

### Phase 5 - Home Screen Information Architecture

- [x] Replace the current setup card with a clearer `Set-Up Instructions` block
- [x] Add a `Calibration` subsection inside that block
- [x] Keep a `Placement` subsection inside that block
- [x] Move setup-order content into the new calibration subsection
- [x] Auto-collapse `Set-Up Instructions` after successful calibration
- [x] Keep the instructions accessible in collapsed form after calibration
- [x] In `Fine-Tune Setup`:
  - [x] add slider tick feedback
  - [x] remove sample pulse UI
  - [x] remove pocket-side UI
  - [x] preserve volume control
  - [x] add haptics master toggle
- [x] In `Calibrate Upright`:
  - [x] remove the second explanatory paragraph
  - [x] update copy for 7-second truthfulness
  - [x] mention completion sound and vibration
  - [x] remove subtext from the `Calibration Not Started` state

### Phase 6 - Visual Redesign and Responsive Layout

- [x] Rework the app into a much bolder 70s roller-rink poster direction
- [x] Use stronger contrast, sharper shapes, stripe/sunburst/halftone motifs, and poster typography
- [x] Avoid rainbow and lava-lamp styling
- [x] Apply the redesign consistently to:
  - [x] splash
  - [x] welcome-back screen
  - [x] onboarding
  - [x] home
  - [x] session
- [x] Implement at least five distinct responsive-layout corrections across the app
- [x] Verify the iPhone 16 Pro cropping issue is resolved structurally, not cosmetically

### Phase 7 - Validation

- [x] Add and update unit tests for:
  - [x] splash/welcome-back launch behavior
  - [x] left-pocket-only settings
  - [x] haptics toggle behavior
  - [x] calibration timing and completion cues
  - [x] audio-volume behavior
- [x] Add and update UI tests for:
  - [x] splash
  - [x] welcome-back screen
  - [x] onboarding to home flow
  - [x] left-pocket-only setup
  - [x] instructions collapsing behavior
  - [x] calibration and start flow
- [x] Run `xcodegen generate`
- [x] Run fresh `build-for-testing`
- [x] Run full unit suite until green
- [x] Run full UI suite until green
- [x] Install and launch the built app in simulator

## Notes

- The internal Swift module may remain `BendedKnee` if needed to keep the test and project structure stable.
- The shipped app name must remain `Drop`.
