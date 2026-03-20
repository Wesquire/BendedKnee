# Final Refinement Master Plan

## Objective

Complete the last product-polish pass by finishing the branded entry flow, repairing onboarding, tightening the coaching cadence, incorporating fresh UX review findings, and then revalidating the entire codebase from a clean build through the full unit and UI suites.

## Phase 1. Scope Lock And Orchestration

- [x] 1.1 Re-read `the_rules.md`
- [x] 1.2 Lock haptic cadence with the user
- [x] 1.3 Spawn a fresh UX/UI + layman + debugger review subagent
- [x] 1.4 Consolidate the initial review findings into the implementation sequence
- [x] 1.5 Fold the final fresh-agent findings into the implementation pass
- [x] 1.6 Keep progress, orchestrator, and evidence files updated as each phase completes

### Phase 1 sequencing notes

- The master rollout owns all file edits.
- Review agents stay read-only so write scopes do not conflict.
- Validation runs happen after the full implementation batch unless a failure blocks forward progress.

## Phase 2. Entry Experience And Branding

- [x] 2.1 Add a branded splash screen shown for `2.5` seconds in normal app launches
- [x] 2.2 Create an in-app Bended Knee logo/brand mark aligned with the app visual language
- [x] 2.3 Add launch configuration hooks so UI tests can control splash behavior deterministically
- [x] 2.4 Confirm the splash, branding, and transition flow survive the final full-suite validation

### Phase 2 deliverables

- `LaunchExperienceView`
- in-app brand mark and iconography
- testable splash timing controls

## Phase 3. Onboarding Repair

- [x] 3.1 Make onboarding full-screen on smaller iPhones
- [x] 3.2 Remove top and bottom cutoff risk with a scrollable adaptive layout
- [x] 3.3 Fix the final onboarding CTA so it always advances into setup
- [x] 3.4 Keep onboarding automation-compatible for UI testing
- [x] 3.5 Confirm there is no remaining first-run dead-end in the final validation pass

### Phase 3 verification focus

- first launch lands in onboarding
- intermediate pages advance reliably
- final continue button dismisses onboarding and reveals setup

## Phase 4. Setup And Session UX Simplification

- [x] 4.1 Move calibration higher in the setup hierarchy
- [x] 4.2 Reduce repeated instructional copy across onboarding, setup, and home
- [x] 4.3 Keep lower-priority help behind progressive disclosure
- [x] 4.4 Remove duplicate stop controls from the session view
- [x] 4.5 Incorporate any additional findings from the fresh UX review agent

### Phase 4 design intent

- keep the primary action above the fold
- reduce copy load
- preserve a low-distraction skating workflow

## Phase 5. Haptics Update

- [x] 5.1 Update haptic cadence mapping to the approved values
- [x] 5.2 Align sample pulse behavior with the updated coaching cadence model
- [x] 5.3 Update direct haptic cadence assertions in tests
- [x] 5.4 Confirm no other timing-dependent flows regressed in the final test run

### Approved cadence

- none: `0`
- gentle: `0.75`
- medium: `0.5`
- strong: `0.33`

## Phase 6. Test Expansion And Fresh Validation

- [x] 6.1 Add or update tests for splash flow behavior
- [x] 6.2 Add or update tests for onboarding completion flow
- [x] 6.3 Add or update tests for the refined setup/support-tools flow
- [x] 6.4 Add or update tests for haptic cadence assertions
- [x] 6.5 Run a fresh simulator `build-for-testing`
- [x] 6.6 Run the full unit suite
- [x] 6.7 Run the full UI suite
- [x] 6.8 Fix every failure until all suites are green

### Phase 6 execution notes

- The current build-for-testing and full unit pass are already green in the latest refinement-derived data.
- The full UI suite is actively being rerun to confirm the final post-fix state.

## Phase 7. Documentation And Evidence Sync

- [x] 7.1 Update `PROGRESS_LOG.md` with the completed refinement work and exact validation commands/results
- [x] 7.2 Update `ORCHESTRATOR_REPORT.md` with the verified end state and fresh-agent findings
- [x] 7.3 Update `TEST_STRATEGY.md` with the newly run validation coverage
- [x] 7.4 Update `FINAL_VALIDATION.md` with the final build and test evidence
- [x] 7.5 Update `APP_FEATURES.md` with the refined user flow and branding changes
- [x] 7.6 Update the phase evidence file for this pass

## Orchestration Ledger

- Completed read-only review agent:
  - `Poincare` audited onboarding, setup, session usability, splash friction, and support-tool discoverability with no file edits.
- Final verification completed:
  - fresh `build-for-testing`
  - fresh full `BendedKneeTests` pass
  - fresh full `BendedKneeUITests` pass
- Main rollout responsibilities:
  - plan synchronization
  - implementation of the queued refinements
  - final validation and evidence capture
