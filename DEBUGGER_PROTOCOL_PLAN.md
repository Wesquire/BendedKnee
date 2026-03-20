# Multi-Agent Debugger Protocol Plan

## Objective

Execute the required three-pass debugger protocol across the entire Bended Knee codebase. Each pass must debug the full app, resolve discovered issues in code, add or adjust tests where needed, and hand off a concrete change summary for the next pass to review.

## Pass Sequence

- [x] Pass 1: full-codebase debug and bug fixing
- [ ] Pass 2: review pass 1 changes, then full-codebase debug and bug fixing
- [ ] Pass 3: review passes 1 and 2 changes, then full-codebase debug and bug fixing
- [x] Fresh post-debug validation:
  - build-for-testing
  - full unit suite
  - full UI suite
- [ ] Final debugger-protocol documentation sync

## Actual Status

- Pass 1 completed locally because new worker spawning was blocked by the platform `agent thread limit reached (max 6)` error.
- Confirmed pass 1 fixes:
  - first-launch splash completion is now persisted only after the splash actually finishes
  - canceled splash tasks no longer mark the splash as consumed
  - preview proximity resets cleanly across repeated starts in the same app process
- Fresh validation already re-run after the pass 1 fixes:
  - `build-for-testing` passed on `/tmp/BendedKneeDebugPass1`
  - full unit suite passed (`97` / `97`)
  - full UI suite passed (`11` / `11`)
- Passes 2 and 3 still need fresh debugger review. If worker slots remain blocked, they should continue locally and the constraint should stay documented explicitly.

## Orchestration Rules

- Passes run sequentially, not concurrently.
- The active pass agent owns the write scope during its pass.
- Later passes must review prior pass changes before making new fixes.
- No pass may revert unrelated user work.
- After all three passes, the main rollout runs the full validation suite and resolves all failures.
