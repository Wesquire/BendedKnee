# App Features

## Overview

`Bended Knee` is a SwiftUI iPhone app for skating posture coaching. It uses a phone in a front pocket to estimate extra bend relative to an upright standing baseline and gives subtle escalating haptic feedback when the user is too upright.

## What The App Does

- Guides the user through a descriptive first-run onboarding flow and a reopenable setup guide
- Lets the user choose a pocket side and a target bend from `0°` to `60°`
- Calibrates a standing baseline after a 3-second delay
- Shows a live numeric bend value
- Runs a live skating session with auto-lock disabled
- Uses escalating haptics when the user is below target
- Lets the user feel a sample pulse in setup
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
- App counts down for 3 seconds
- Baseline locks only if enough stable samples are captured
- Noisy calibration fails with an explicit retry message
- If recalibration is interrupted, the last good baseline is preserved

### Feedback

- On target: haptics stop
- Below target: haptics escalate by deficit zone
- Pocket removed: session pauses haptics
- Invalid placement: coaching pauses until placement is corrected

## Main User Flow

1. Launch the app
2. Read onboarding
3. Choose the skating pocket and set target bend
4. Place the phone in a front pocket, top-up, screen facing the thigh
5. Optionally feel a sample pulse
6. Calibrate upright
7. Start the live session
8. Skate and respond to the live number and haptics
9. End the session

## Latest Verified Test Results

- Focused `SessionViewModelTests`: `27` passed, `0` failed
- Full unit suite: `87` passed, `0` failed
- Full UI suite: `10` passed, `0` failed

## Automated Tests Run

- Unit coverage:
  - bend-angle math
  - calibration stability thresholds
  - haptic zone mapping
  - onboarding and settings persistence
  - recalibration interruption recovery
  - invalid placement handling
  - pocket removal and auto-resume
  - session start when already out of pocket
  - pocket-side revalidation after switching setup
- UI coverage:
  - first-launch onboarding
  - setup controls after onboarding
  - calibration enabling start
  - session start/end controls
  - noisy-calibration failure message
  - motion-unavailable state
  - paused pocket-removal state
  - pocket-side selection in setup
  - setup guide re-entry
  - sample/setup controls exposure

## Remaining Risks

- Real-device haptic tuning
- Real-device pocket-removal validation
- Combined one-shot Xcode runner instability on this machine
