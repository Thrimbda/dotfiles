# Axiom Remove Default Keep Awake - Tasks

## Quick Restore
**Current Phase**: Review And Delivery
**Current Checkpoint**: Complete PR lifecycle
**Progress**: 9/10 tasks complete

---

## Phase 1: Contract COMPLETE
- [x] Capture task scope | Acceptance: `plan.md` states goal, problem, acceptance, assumptions, constraints, risks, scope, non-goals, design summary, and phases.
- [x] Confirm worktree boundary | Acceptance: implementation occurs in `.worktrees/axiom-remove-default-keep-awake/` on `legion/axiom-remove-default-keep-awake-disable-inhibitor`.

## Phase 2: Implementation COMPLETE
- [x] Remove default Keep Awake helper | Acceptance: no `axiom-caelestia-keep-awake` helper remains in active Axiom host config.
- [x] Remove default startup enable hook | Acceptance: no Axiom startup hook runs `idleInhibitor enable` by default.
- [x] Update active docs/wiki | Acceptance: README and wiki describe Keep Awake as manual and preserve 15/30 idle timing.

## Phase 3: Verification COMPLETE
- [x] Run targeted Nix/static validation | Acceptance: evaluated Axiom config has no default Keep Awake hook/helper and keeps 900/1800 idle policy.
- [x] Run focused search checks | Acceptance: active Axiom config/docs have no current default `idleInhibitor enable` guidance.
- [x] Run formatting/build checks | Acceptance: `git diff --check` and appropriate Nix validation pass or limitations are recorded.

## Phase 4: Review And Delivery IN PROGRESS
- [x] Record review and walkthrough evidence | Acceptance: `docs/test-report.md`, `docs/review-change.md`, `docs/report-walkthrough.md`, and `docs/pr-body.md` exist.
- [ ] Complete PR lifecycle | Acceptance: branch pushed, PR created, auto-merge attempted, checks followed, terminal state recorded, worktree cleaned up, and main workspace refreshed.
