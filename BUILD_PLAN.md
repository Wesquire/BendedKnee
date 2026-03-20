# Bended Knee Build Plan

## Phase 0. Requirements Lock

- ~~0.1 Read and adopt repo rules from `the_rules.md`~~
- ~~0.2 Inspect workspace and confirm current repo state~~
- ~~0.3 Spawn UX/UI, Full Stack, Layman, and Orchestrator agents for parallel analysis~~
- ~~0.4 Consolidate agent findings into a single technical/product recommendation~~
- ~~0.5 Resolve blocked product decisions with user~~
- ~~0.6 Finalize approved measurement model~~
- ~~0.7 Finalize approved session workflow~~
- ~~0.8 Finalize target-angle semantics~~
- ~~0.9 Finalize runtime/background expectations~~

Acceptance criteria:
- Measurement model is explicitly approved.
- Phone placement/orientation rules are explicitly approved.
- Session behavior and feedback expectations are explicitly approved.

## Phase 1. Technical Design

- ~~1.1 Define SwiftUI app architecture~~
- ~~1.2 Define motion sampling pipeline using `CoreMotion`~~
- ~~1.3 Define baseline calibration algorithm~~
- ~~1.4 Define bend-angle proxy calculation~~
- ~~1.5 Define haptic intensity and cadence mapping~~
- ~~1.6 Define calibration failure and recovery states~~
- ~~1.7 Define testable domain boundaries~~

Acceptance criteria:
- Design documents specify exactly what signal is measured.
- State transitions, thresholds, and invalidation rules are documented.

## Phase 2. Product and UX Design

- ~~2.1 Define onboarding flow~~
- ~~2.2 Define calibration screen and countdown behavior~~
- ~~2.3 Define active session screen~~
- ~~2.4 Define settings and target controls~~
- ~~2.5 Define accessibility and safety copy~~
- ~~2.6 Define summary/history scope~~

Acceptance criteria:
- UI wording matches the approved technical behavior.
- All key user states are specified.

## Phase 3. Project Scaffolding

- ~~3.1 Create iOS Swift/Xcode project~~
- ~~3.2 Create app target~~
- ~~3.3 Create unit and UI test targets~~
- ~~3.4 Establish folder structure~~
- ~~3.5 Verify clean local build~~
- ~~3.6 Verify tests execute~~

Acceptance criteria:
- Project builds successfully.
- Test targets run successfully.

## Phase 4. Motion Engine

- ~~4.1 Implement motion availability and permissions handling~~
- ~~4.2 Implement 3-second calibration delay~~
- ~~4.3 Implement baseline sampling and averaging~~
- ~~4.4 Implement live motion updates~~
- ~~4.5 Implement filtering/smoothing~~
- ~~4.6 Implement bend-angle proxy estimator~~
- 4.7 Implement calibration invalidation detection

Acceptance criteria:
- Core calculations are covered by tests.
- Calibration and live tracking work on device.

## Phase 5. Haptics Engine

- ~~5.1 Implement `CoreHaptics` capability checks~~
- ~~5.2 Implement haptic deficit zones~~
- ~~5.3 Implement cadence/rate limiting~~
- ~~5.4 Implement subtle fallback behavior where needed~~
- 5.5 Verify low-noise behavior on device

Acceptance criteria:
- Haptics are bounded, stable, and non-spammy.

## Phase 6. UI Implementation

- ~~6.1 Implement onboarding~~
- ~~6.2 Implement calibration flow~~
- ~~6.3 Implement session flow~~
- ~~6.4 Implement settings~~
- ~~6.5 Implement error and recovery states~~
- ~~6.6 Implement summary/history if approved~~

Acceptance criteria:
- All primary flows are functional.
- Error states are reachable and recoverable.

## Phase 7. Validation

- ~~7.1 Add unit tests for angle math and thresholds~~
- ~~7.2 Add integration tests for session state~~
- ~~7.3 Add UI tests for core flows~~
- 7.4 Run device validation for motion and haptics
- ~~7.5 Run regression pass after each substantial change~~

Acceptance criteria:
- Tests pass.
- Device validation confirms the app runs and behaves as intended.

## Phase 8. Layman Review Loop

- 8.1 Run layman use-case review
- 8.2 Record confusion points and edge cases
- 8.3 Triage with UX/UI and Full Stack recommendations
- 8.4 Implement approved refinements
- 8.5 Re-test

Acceptance criteria:
- Critical usability issues are addressed.
- Final build remains verified after refinement.

## Current Recommendation

- Recommended v1: single-iPhone front-pocket thigh-angle proxy, not true anatomical knee-angle measurement.
- Reason: this is the simplest technically honest approach that matches the skating coaching use case.
- Final runtime decision:
  - The app remains foreground-active during a session and disables auto-lock.
  - The app does not claim to keep running with continuous motion plus haptics while locked and suspended, because that is not a reliable iPhone-only iOS 17 model.
- User-approved decisions:
  - Single-phone thigh-angle proxy is the desired approach.
  - Both left and right front pockets must be supported.
  - Phone orientation is fixed: top-up, screen facing the thigh.
  - Live numeric angle is required.
  - Haptics-only feedback is required.
  - No session history is required.
  - Target angle input range can be `0` to `60` degrees.
  - Haptics should stop automatically when phone removal from the pocket is detected.
  - Minimum deployment target can be `iOS 17`.
- Current verified state:
  - The SwiftUI app is implemented.
  - Local iOS Simulator build passes.
  - Local unit and UI tests pass.
  - Remaining work is real-device validation and any refinement that follows it.
