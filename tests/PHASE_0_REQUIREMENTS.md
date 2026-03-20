# Phase 0 Requirements Evidence

## Completed

- Read and adopted `the_rules.md`.
- Confirmed current repo state.
- Spawned four agents for parallel requirement analysis.
- Consolidated product, technical, layman, and orchestration findings.

## Confirmed So Far

- Platform: iOS
- Language: Swift
- Core behavior: user calibrates while standing, then receives escalating haptics when not bent enough while skating
- Calibration delay: 3 seconds before setting standing baseline
- Target angle: user-adjustable
- Measurement model: single-phone thigh-angle proxy
- Pockets supported: left and right front pockets
- Fixed phone orientation: top-up, screen facing thigh
- Live numeric angle: required
- Feedback mode: haptics only
- Session history: not required
- App purpose: skating training only
- Target range: `0` to `60` degrees
- Pocket-removal behavior: automatically stop/pause haptics when removal is detected
- Deployment target: `iOS 17`
- Runtime model: foreground-active session with auto-lock disabled

## Critical Technical Finding

- Single-phone front-pocket sensing supports a bend proxy based on thigh/device orientation relative to a standing baseline.
- Single-phone front-pocket sensing does not directly support true anatomical knee-angle measurement.

## Current Status

- Phase 0 is resolved.
- Runtime expectations are finalized to the technically honest iPhone-only model.

## Source-Backed Blocker Note

- Apple states that iOS suspends apps shortly after they move to the background and that there is no general-purpose mechanism for running code continuously in the background.
- Apple also documents `CHHapticEngine.StoppedReason.applicationSuspended`, indicating the haptic engine stops when the application is suspended.
- This is why the implementation keeps the app active in the foreground during a session instead of claiming reliable locked/background behavior.
