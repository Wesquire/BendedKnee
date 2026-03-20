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
- Inline first-time support-tool exposure
- Calibration enabling the session
- Session screen showing stop control after start
- Calibration failure message
- Motion-unavailable state
- Pocket-removal paused state
- Forced splash visibility in UI testing

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

- `xcodebuild -project BendedKnee.xcodeproj -scheme BendedKnee -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -derivedDataPath /tmp/BendedKneeFinalPolish build-for-testing`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeFinalPolish/Build/Products/BendedKnee_iphonesimulator26.2-arm64.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeTests`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeFinalPolish/Build/Products/BendedKnee_iphonesimulator26.2-arm64.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeUITests`

## Latest Results

- Full unit suite: `93` tests passed, `0` failures
- Full UI suite: `11` tests passed, `0` failures

## Notes

- The final split full unit and full UI suites are green on the post-refinement artifact set at `/tmp/BendedKneeFinalPolish`.
- The new tests added in this pass cover:
  - first-launch-only production splash behavior
  - truthful start-session availability when placement becomes invalid
  - support-tool exposure regardless of whether they are inline or disclosed
- A direct combined all-tests one-shot run remains more fragile than split suite execution on this machine because of `CoreSimulator` / Xcode runner behavior.
- Real-device validation remains required for motion feel, proximity behavior, and haptic tuning.
