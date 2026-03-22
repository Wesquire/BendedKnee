# Phase 13 Evidence - Launch, Layout, Audio, and Setup Overhaul

## Scope

This evidence file tracks the implementation and validation for:

- cold-launch splash timing
- recurring welcome-back screen
- left-pocket-only rules
- haptics master toggle
- preserved pulse-audio coaching
- 7-second calibration truthfulness
- home-screen setup IA changes
- stronger 70s poster visual redesign
- responsive layout fixes for iPhone 16 Pro

## Implementation Log

- Added a recurring welcome-back entry screen and routed launch flow through onboarding -> welcome-back -> home/session as appropriate.
- Extended the cold-launch splash to `6` seconds in production while keeping UI-test launch behavior deterministic.
- Converted setup and coaching copy to left-pocket-only rules and removed right-pocket selection from settings UI.
- Added a master `Haptics` toggle that disables calibration cues, live session haptics, and slider-tick feedback.
- Kept pulse audio active for both session coaching and calibration cues, all driven by the existing volume slider with `0` acting as silent mode.
- Rebuilt the home screen around a clearer `Set-Up Instructions` card with dedicated `Calibration` and `Placement` sections.
- Auto-collapsed `Set-Up Instructions` after successful calibration while keeping the guidance available afterward.
- Updated calibration timing and copy to a truthful `7` second total flow with completion sound/vibration messaging.
- Added a new poster-style visual system and applied it across splash, onboarding, welcome-back, home, and session screens.
- Tightened safe-area-aware width caps, spacing, and content scaling across the main screens to address tall-phone cropping on iPhone 16 Pro class devices.
- Regenerated the Xcode project so the new `WelcomeBackView.swift` file is included in the app target.
- Reviewed the `com.apple.CoreMotion.plist` console warning and confirmed there is no app-side file access to suppress; the repo does not read that managed-preferences file directly.

## Validation Log

- `xcodegen generate` passed
- `build-for-testing` passed on `/tmp/DropPhase13`
- Full unit suite passed: `103 / 103`
- Full UI suite passed: `11 / 11`
- Direct simulator install and launch passed: `com.drop.app: 41815`
- Targeted reruns were also completed for the splash and calibration-failure UI paths while stabilizing the suite
