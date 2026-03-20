# Final Refinement Master Plan

## Phase 1. Scope Lock And Orchestration

- [x] 1.1 Re-read `the_rules.md`
- [x] 1.2 Lock haptic cadence with the user
- [x] 1.3 Spawn a fresh UX/UI + layman + debugger review subagent
- [x] 1.4 Consolidate subagent findings into the implementation sequence
- [ ] 1.5 Keep progress, orchestrator, and evidence files updated as each phase completes

## Phase 2. Entry And Onboarding Repair

- [ ] 2.1 Add a branded splash screen shown for `2.5` seconds
- [ ] 2.2 Create an in-app Bended Knee logo and icon that fit the app visual language
- [ ] 2.3 Make onboarding truly full-screen on smaller iPhones
- [ ] 2.4 Remove top/bottom cutoff risk in onboarding layout
- [ ] 2.5 Fix the final onboarding CTA so it always advances into setup
- [ ] 2.6 Keep onboarding compatible with UI testing

## Phase 3. UX And Flow Simplification

- [ ] 3.1 Move the main calibration action higher in setup
- [ ] 3.2 Reduce repeated instructional copy across onboarding, setup, and home
- [ ] 3.3 Keep less-critical help as progressive disclosure
- [ ] 3.4 Remove duplicate session stop controls
- [ ] 3.5 Keep session UI readable and low distraction after simplification

## Phase 4. Haptics Update

- [ ] 4.1 Update haptic cadence mapping
- [ ] 4.2 Confirm sample pulse behavior still feels aligned with the new cadence model
- [ ] 4.3 Update all tests that assert haptic zone behavior

Approved cadence:

- none: `0`
- gentle: `0.75`
- medium: `0.5`
- strong: `0.33`

## Phase 5. Test Expansion

- [ ] 5.1 Add tests for splash flow behavior
- [ ] 5.2 Add tests for onboarding final-step completion
- [ ] 5.3 Add tests for new UX flow changes where appropriate
- [ ] 5.4 Add/update haptic cadence assertions

## Phase 6. Final Validation

- [ ] 6.1 Run a fresh simulator `build-for-testing`
- [ ] 6.2 Run focused regressions for changed logic where helpful
- [ ] 6.3 Run the full unit suite
- [ ] 6.4 Run the full UI suite
- [ ] 6.5 Fix every failure until the suites are green

## Phase 7. Documentation Sync

- [ ] 7.1 Update `PROGRESS_LOG.md`
- [ ] 7.2 Update `ORCHESTRATOR_REPORT.md`
- [ ] 7.3 Update `TEST_STRATEGY.md`
- [ ] 7.4 Update `FINAL_VALIDATION.md`
- [ ] 7.5 Update `APP_FEATURES.md`
- [ ] 7.6 Update the phase evidence file

## Current Orchestration Notes

- The local implementation write scope is the app, tests, and docs.
- The spawned subagent has a read-only review scope and will not edit files.
- UX findings already queued for implementation:
  - raise the calibration CTA
  - remove duplicate stop controls
  - reduce repeated instructional copy
