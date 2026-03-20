# Phase 8 Multi-Agent Debugger Protocol

## Goal

Run the required three-pass debugger protocol across the full Swift iOS codebase, with each pass fixing bugs instead of only reporting them, then revalidate the entire project.

## Tracker

- [x] Create debugger protocol tracking docs
- [x] Run debugger pass 1
- [ ] Run debugger pass 2
- [ ] Run debugger pass 3
- [x] Run fresh build-for-testing
- [x] Run fresh full unit validation
- [x] Run fresh full UI validation
- [ ] Sync final docs for the debugger effort

## Pass 1 Outcome

- Pass 1 was completed locally because replacement debugger workers could not be spawned after the initial worker failed and the platform returned `agent thread limit reached (max 6)`.
- Fixed app bugs:
  - splash completion persistence now happens only after the splash actually completes
  - canceled splash tasks no longer falsely consume first-launch splash state
  - preview proximity state resets between repeated starts, preventing stale "phone removed" carry-over in repeated-session test harness use
- Added regression coverage:
  - `AppLaunchConfigurationTests.testCancelledSplashDelayDoesNotPersistCompletion`
  - `AppLaunchConfigurationTests.testCompletedSplashDelayPersistsCompletion`
  - `SessionViewModelTests.testPreviewProximityServiceResetsStateAcrossStarts`

## Validation Evidence

- `xcodebuild -project /Users/wesquire/Github/Bended\ Knee/BendedKnee.xcodeproj -scheme BendedKnee -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -derivedDataPath /tmp/BendedKneeDebugPass1 build-for-testing`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeDebugPass1/Build/Products/BendedKnee_iphonesimulator26.2-arm64.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeTests/AppLaunchConfigurationTests`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeDebugPass1/Build/Products/BendedKnee_iphonesimulator26.2-arm64.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeTests/SessionViewModelTests`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeDebugPass1/Build/Products/BendedKnee_iphonesimulator26.2-arm64.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeTests`
- `xcodebuild test-without-building -xctestrun /tmp/BendedKneeDebugPass1/Build/Products/BendedKnee_iphonesimulator26.2-arm64.xctestrun -destination 'platform=iOS Simulator,arch=arm64,id=B0062079-F40F-4D87-B505-1B4AE90B5E13' -only-testing:BendedKneeUITests`

## Current Blocker

- Passes 2 and 3 are not complete yet.
- Fresh worker spawning is still blocked by the current platform agent-thread cap, so later debugger passes must either wait for capacity or continue locally with the limitation documented honestly.
