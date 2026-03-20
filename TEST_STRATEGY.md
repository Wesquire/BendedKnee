# Bended Knee Test Strategy

## Scope

This document defines the current testing strategy for the Bended Knee iOS app and records the validation actually executed in this pass.

## Test Layers

### Unit Tests

- Bend-angle estimator math
- Calibration averaging and spread thresholds
- Haptic zone mapping and labels
- Session-state model equality and smoothing helpers
- Session view-model flow
- Motion-unavailable handling
- Calibration success and noisy-calibration failure
- Pocket removal pause and auto-resume
- Initial out-of-pocket session start handling
- Recalibration interruption recovery
- Pocket-side revalidation after switching setup
- Target clamping
- Onboarding reopening
- Stale pre-calibration sample rejection

### Integration Tests

- Calibration countdown flow
- Baseline-ready transition
- Session start/stop transitions
- Pocket removal and return transitions
- Settings persistence

### UI Tests

- First-launch onboarding gate
- Setup screen after onboarding
- Pocket-side selector and setup guide re-entry
- Calibration enabling the session
- Session screen showing stop control after start
- Calibration failure message
- Motion-unavailable state
- Pocket-removal paused state

### Manual Device Validation

- Standing calibration on real hardware
- Pocket stability during skating
- Haptic subtlety and audibility on-device
- Real proximity behavior in real pockets
- Battery impact over longer sessions

## Mandatory Truthfulness Constraint

- No test may be claimed as passing unless it has actually been run and passed.
- If tests fail, the failures must be resolved before completion is claimed.

## Latest Executed Validation

- `xcodebuild -project BendedKnee.xcodeproj -scheme BendedKnee -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -derivedDataPath /tmp/BendedKneeDerivedPass3 build-for-testing`
- `xcrun simctl install B0062079-F40F-4D87-B505-1B4AE90B5E13 /tmp/BendedKneeDerivedPass3/Build/Products/Debug-iphonesimulator/BendedKnee.app`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeDerivedPass3/Build/Products/BendedKnee_unit_only.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeTests/SessionViewModelTests`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeDerivedPass3/Build/Products/BendedKnee_unit_only.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13'`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeDerivedPass3/Build/Products/BendedKnee_iphonesimulator26.2-arm64.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeUITests`

## Latest Results

- Focused `SessionViewModelTests`: `27` tests passed, `0` failures
- Full unit suite: `87` tests passed, `0` failures
- Full UI suite: `10` tests passed, `0` failures

## Notes

- The final split full unit and full UI suites are green on the pass-3 artifact set.
- This machine sometimes needs a manual `simctl install` and an explicit `arch=arm64` destination before `xcodebuild test-without-building` becomes reliable again after simulator instability.
- A direct combined all-tests one-shot run remains intermittently unstable on this machine because `CoreSimulator` / the Xcode runner can interrupt or early-exit before a unified summary completes.
- Real-device validation remains required for motion feel, proximity behavior, and haptic tuning.
