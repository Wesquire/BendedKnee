# Phase 7 Entry, UX, And Haptics

## Goal

Close the last product gaps in entry flow, onboarding, usability polish, and haptic cadence, then revalidate the entire codebase.

## Tracked Work

- [x] Re-read `the_rules.md`
- [x] Lock the haptic cadence with the user
- [x] Spawn a fresh UX/UI + layman review agent
- [x] Create the splash screen and branded logo/icon
- [x] Repair the onboarding layout and last-step progression
- [x] Simplify setup/session UX based on the initial review findings
- [x] Update haptic cadence and related logic/tests
- [x] Receive and evaluate the fresh-agent walkthrough findings
- [x] Run fresh `build-for-testing`, full unit, and full UI validation to the final green state
- [x] Update docs with the final verified state

## Detailed Sequence

### 1. Entry experience

- [x] Add the branded splash screen
- [x] Add the Bended Knee brand mark and logo treatment
- [x] Add deterministic splash controls for UI tests

### 2. Onboarding repair

- [x] Make the onboarding layout adapt to small screens
- [x] Keep content reachable without clipping
- [x] Fix the terminal CTA handoff into setup

### 3. UX simplification

- [x] Raise calibration above the fold
- [x] Reduce repeated copy
- [x] Keep secondary support tools collapsible
- [x] Remove duplicate stop controls

### 4. Haptic cadence

- [x] Apply the approved cadence:
  - none `0`
  - gentle `0.75`
  - medium `0.5`
  - strong `0.33`
- [x] Update haptic assertions

### 5. Validation and closure

- [x] Run fresh build-for-testing
- [x] Run fresh full unit validation
- [x] Run fresh full UI validation
- [x] Sync all closing documentation
