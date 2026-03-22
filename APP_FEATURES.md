# App Features

## Overview

`Drop` is a SwiftUI iPhone app for skating posture coaching. It uses a phone in the left front pocket to estimate extra bend relative to an upright standing baseline and gives fast pulse audio plus optional haptic coaching when the user is too upright.

## What The App Does

- Guides the user through a descriptive first-run onboarding flow, then shows a recurring welcome-back screen on later launches
- Shows a branded `6` second splash screen on cold launch
- Lets the user choose a target bend from `0°` to `60°`
- Calibrates a standing baseline through a truthful `7` second flow
- Shows a live numeric bend value
- Runs a live skating session with auto-lock disabled
- Uses escalating pulse audio and optional haptics when the user is below target
- Pauses automatically when the phone leaves the pocket
- Resumes automatically when the phone returns
- Rejects invalid phone placement and asks the user to reinsert the phone top-up with the screen toward the thigh

## Core Functional Model

### Measurement

- The app measures a front-pocket tilt proxy, not a true knee-joint angle.
- Live bend is calculated as:
  - `smoothed current tilt - calibrated standing baseline`
  - clamped at zero

### Calibration

- User stands upright and still
- User should set target, haptics, and audio before calibrating
- App uses a `4` second prep countdown plus `3` seconds of capture
- Baseline locks only if enough stable samples are captured
- Noisy calibration fails with an explicit retry message
- If recalibration is interrupted, the last good baseline is preserved

### Feedback

- On target: pulse audio and haptics stop
- Below target: pulse audio continues and haptics escalate by deficit zone
- Pocket removed: session coaching pauses
- Invalid placement: coaching pauses until placement is corrected
- The app must remain open and foregrounded during the session

## Main User Flow

1. Launch the app
2. On first launch, watch the branded splash and read onboarding
3. On later launches, dismiss the welcome-back screen
4. Set target bend, haptics, and pulse-audio volume
5. Place the phone in the left front pocket, top-up, screen facing the thigh
6. Calibrate upright
7. Start the live session
8. Keep the app open while skating and respond to the live number, pulse audio, and haptics
9. End the session with the large session control

## Latest Verified Test Results

- Full unit suite: `103` passed, `0` failed
- Full UI suite: `11` passed, `0` failed

## Automated Tests Run

- Unit coverage:
  - bend-angle math
  - calibration stability thresholds
  - haptic zone mapping
  - splash duration and UI-test splash overrides
  - onboarding, welcome-back, and settings persistence
  - recalibration interruption recovery
  - invalid placement handling
  - truthful start-session enablement
  - haptics master-toggle behavior
  - slider tick behavior
  - calibration audio cue triggering
  - pocket removal and auto-resume
  - session start when already out of pocket
  - left-pocket-only persisted setup behavior
- UI coverage:
  - first-launch onboarding
  - forced splash delay behavior
  - returning-user welcome-back flow
  - setup controls after onboarding
  - calibration enabling start
  - session start/end controls
  - noisy-calibration failure message
  - motion-unavailable state
  - paused pocket-removal state
  - set-up instructions visibility
  - haptics/audio controls exposure

## Remaining Risks

- Real-device haptic tuning
- Real-device pocket-removal validation
- Combined one-shot Xcode runner instability on this machine

## Phase 13 Delivered Feature Set

- Launch flow now uses:
  - a `6` second cold-launch splash
  - a recurring welcome-back screen after onboarding is complete
- Coaching model now uses:
  - left-pocket-only operation
  - full-session pulse audio plus calibration audio through the existing volume slider
  - a master haptics toggle that disables all haptic cues
- Home screen now uses:
  - a `Set-Up Instructions` card with `Calibration` and `Placement` sections
  - no pocket-side controls
  - no sample-pulse preview button
  - auto-collapsing instructions after successful calibration
- Visual system now uses:
  - stronger poster gradients
  - stripe and sunburst motifs
  - higher-contrast retro rink color treatment
  - responsive bounded layouts across splash, onboarding, welcome-back, home, and session
