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

## Phase 1. Technical Design

- ~~1.1 Define SwiftUI app architecture~~
- ~~1.2 Define motion sampling pipeline using `CoreMotion`~~
- ~~1.3 Define baseline calibration algorithm~~
- ~~1.4 Define bend-angle proxy calculation~~
- ~~1.5 Define haptic intensity and cadence mapping~~
- ~~1.6 Define calibration failure and recovery states~~
- ~~1.7 Define testable domain boundaries~~

## Phase 2. Product and UX Design

- ~~2.1 Define onboarding flow~~
- ~~2.2 Define calibration screen and countdown behavior~~
- ~~2.3 Define active session screen~~
- ~~2.4 Define settings and target controls~~
- ~~2.5 Define accessibility and safety copy~~
- ~~2.6 Define summary/history scope~~

## Phase 3. Project Scaffolding

- ~~3.1 Create iOS Swift/Xcode project~~
- ~~3.2 Create app target~~
- ~~3.3 Create unit and UI test targets~~
- ~~3.4 Establish folder structure~~
- ~~3.5 Verify clean local build~~
- ~~3.6 Verify tests execute~~

## Phase 4. Motion Engine

- ~~4.1 Implement motion availability and permissions handling~~
- ~~4.2 Implement 3-second calibration delay~~
- ~~4.3 Implement baseline sampling and averaging~~
- ~~4.4 Implement live motion updates~~
- ~~4.5 Implement filtering/smoothing~~
- ~~4.6 Implement bend-angle proxy estimator~~
- 4.7 Implement calibration invalidation detection on real device

## Phase 5. Haptics Engine

- ~~5.1 Implement `CoreHaptics` capability checks~~
- ~~5.2 Implement haptic deficit zones~~
- ~~5.3 Implement cadence/rate limiting~~
- ~~5.4 Implement subtle fallback behavior where needed~~
- 5.5 Verify low-noise behavior on device

## Phase 6. UI Implementation

- ~~6.1 Implement onboarding~~
- ~~6.2 Implement calibration flow~~
- ~~6.3 Implement session flow~~
- ~~6.4 Implement settings~~
- ~~6.5 Implement error and recovery states~~
- ~~6.6 Implement summary/history if approved~~

## Phase 7. Validation

- ~~7.1 Add unit tests for angle math and thresholds~~
- ~~7.2 Add integration tests for session state~~
- ~~7.3 Add UI tests for core flows~~
- 7.4 Run device validation for motion and haptics
- ~~7.5 Run regression pass after each substantial change~~

## Phase 8. Layman Review Loop

- ~~8.1 Run layman use-case review~~
- ~~8.2 Record confusion points and edge cases~~
- ~~8.3 Triage with UX/UI and Full Stack recommendations~~
- ~~8.4 Implement approved refinements~~
- ~~8.5 Re-test~~

## Phase 9. Multi-Agent Debugging

- ~~9.1 Debugger pass 1 complete~~
- ~~9.2 Address debugger pass 1 findings~~
- ~~9.3 Debugger pass 2 complete~~
- ~~9.4 Address debugger pass 2 findings~~
- ~~9.5 Debugger pass 3 complete~~
- ~~9.6 Address debugger pass 3 findings~~

## Current Recommendation

- Recommended v1: single-iPhone front-pocket thigh-angle proxy, not true anatomical knee-angle measurement.
- Reason: it is the simplest technically honest model that matches the skating coaching use case.
- Final runtime decision:
  - the app remains foreground-active during a session
  - auto-lock is disabled while a session is live
  - the app does not claim reliable locked-and-suspended continuous motion plus haptics on iPhone-only `iOS 17`

## Current Verified State

- The SwiftUI app is implemented.
- Final simulator `build-for-testing` passes on the pass-3 artifact set.
- Full split-suite simulator validation passes:
  - focused `SessionViewModelTests`: `27` passed
  - full unit suite: `87` passed
  - full UI suite: `10` passed
- The required three-pass debugger-agent review is complete and the findings were addressed:
  - pass 1:
    - do not stop sessions on `.inactive`
    - preserve the previous baseline when recalibration is interrupted
  - pass 2:
    - remove duplicate app-level scene-phase handling that still paused on `.inactive`
  - pass 3:
    - honor an initial `proximity == false` state when starting a session
    - do not clear `placementInvalid` optimistically when the user switches pocket side
- Remaining work:
  - real-device motion and haptic validation
  - optional stabilization of a one-shot combined test runner on this machine; split full unit and full UI validation already pass
