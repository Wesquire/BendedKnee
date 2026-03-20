# Orchestrator Report

## Current Repo State

- The repo now contains a generated iOS Swift project, app source, tests, and tracking docs.
- The current implementation is a working SwiftUI app for iPhone on `iOS 17`.

## Agent Work Summary

- UX/UI recommendation:
  - Build a simple coaching app focused on getting low enough while skating.
  - Keep setup light, use clear calibration language, and make the live session screen low distraction.
- Full Stack recommendation:
  - Use a single-phone thigh-angle proxy for `v1`.
  - Use `CMDeviceMotion.gravity` for a baseline-relative bend proxy and `CoreHaptics` for subtle escalating feedback.
- Layman recommendation:
  - Keep setup extremely simple and explain exactly what is being measured.
  - Make the app pause haptics when the phone leaves the pocket and avoid clutter or saved history.
- Orchestrator recommendation:
  - Finalize measurement semantics before code, then proceed through architecture, implementation, and validation with written evidence.

## Final Product Decision

- SwiftUI iPhone app
- `CoreMotion`-based baseline-relative bend proxy
- `CoreHaptics`-based escalating subtle feedback
- 3-second calibration delay before standing baseline capture
- Adjustable target angle
- Foreground-active session model with auto-lock disabled during a live session

## Critical Technical Truth

- A phone in one front pocket cannot directly measure true knee joint angle by itself.
- It can measure device/thigh orientation relative to gravity and compare it to a standing baseline.

## Implemented Architecture

- App shell:
  - `SwiftUI`
  - `RootView` switches between setup and session states
- Motion:
  - `CMDeviceMotion.gravity`
  - smoothing via `ExponentialSmoother`
  - baseline averaging via `CalibrationAccumulator`
- Angle math:
  - `atan2(abs(gravity.z), max(0.001, -gravity.y))`
  - bend proxy = `currentRawAngle - baselineAngle`, clamped at zero
- Session behavior:
  - 3-second calibration countdown
  - live numeric angle
  - target range `0...60`
  - escalating haptic zones from deficit
  - pocket removal pauses haptics
  - pocket return resumes automatically
- Persistence:
  - target angle
  - pocket side
  - onboarding dismissal

## User Decisions Recorded

- `v1` uses the thigh-angle proxy approach.
- The phone must support both left and right front pockets.
- Orientation is fixed: top-up and screen facing the thigh.
- The session screen should show a live numeric angle.
- Feedback should be haptics only.
- Session history should not be stored.
- Target platform can be `iOS 17`.
- Runtime expectation is resolved to a technically honest foreground-active model.

## Verification Status

- Local build: passed
- Full simulator test suite: passed
- Current automated coverage:
  - angle math
  - haptic zone mapping
  - session state models
  - session calibration and proximity flows
  - core UI onboarding/calibration flow

## Remaining Gaps

- Real-device validation has not been performed in this environment.
- Calibration invalidation while the user moves during calibration is not yet a dedicated failure state.
- Fine-tuning haptic subtlety for real skating conditions still requires device iteration.
