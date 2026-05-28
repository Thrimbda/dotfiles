# Axiom Caelestia Idle Timeouts - Tasks

## Quick Restore
**Current Phase**: Review And Delivery
**Current Checkpoint**: Complete PR lifecycle
**Progress**: 9/10 tasks complete

---

## Phase 1: Contract COMPLETE
- [x] Capture task scope | Acceptance: `plan.md` states goal, problem, acceptance, assumptions, constraints, risks, scope, non-goals, design summary, and phases.
- [x] Confirm worktree boundary | Acceptance: implementation occurs in `.worktrees/axiom-caelestia-idle-timeouts/` on `legion/axiom-caelestia-idle-timeouts-align-idle`.

## Phase 2: Implementation COMPLETE
- [x] Align Caelestia idle defaults | Acceptance: Axiom Caelestia settings include 900 second lock and 1800 second DPMS entries with no 600 second sleep action.
- [x] Migrate persisted shell config | Acceptance: session pre-start migration writes the same `general.idle` policy into existing mutable `shell.json` while preserving unrelated settings.
- [x] Update active docs/wiki | Acceptance: README and wiki current truth explain aligned Caelestia/Hypridle idle timers and no automatic idle sleep.

## Phase 3: Verification COMPLETE
- [x] Run targeted Nix/static validation | Acceptance: generated settings and migration helper contain the intended values and no sleep action.
- [x] Run focused search checks | Acceptance: active Axiom config/docs do not contain current automatic idle sleep actions.
- [x] Run formatting/build checks | Acceptance: `git diff --check` and appropriate Nix validation pass or limitations are recorded.

## Phase 4: Review And Delivery IN PROGRESS
- [x] Record review and walkthrough evidence | Acceptance: `docs/test-report.md`, `docs/review-change.md`, `docs/report-walkthrough.md`, and `docs/pr-body.md` exist.
- [ ] Complete PR lifecycle | Acceptance: branch pushed, PR created, auto-merge attempted, checks followed, terminal state recorded, worktree cleaned up, and main workspace refreshed.
