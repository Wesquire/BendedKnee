# Phase 1 Architecture Checklist

## Completed

- Motion sensing model finalized:
  - `CMDeviceMotion.gravity`
  - foreground-active session
- Calibration algorithm finalized:
  - 3-second countdown
  - averaged standing baseline
  - fallback to last sampled angle if calibration window is sample-light
- Bend-angle proxy math finalized:
  - raw angle from gravity `y/z`
  - baseline subtraction
  - clamp to zero
- Haptic mapping finalized:
  - deficit zones
  - cadence per zone
  - `CoreHaptics` with `UIImpactFeedbackGenerator` fallback
- App-state design finalized:
  - onboarding
  - idle
  - calibrating
  - ready
  - running
  - paused-pocket-removed
  - unavailable

## Status

- Complete
