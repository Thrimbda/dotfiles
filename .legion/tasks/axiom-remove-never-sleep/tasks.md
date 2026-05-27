# Axiom Remove Never Sleep - Tasks

## Quick Restore
**Current Phase**: Review And Delivery
**Current Checkpoint**: Complete PR lifecycle
**Progress**: 9/10 tasks complete

---

## Phase 1: Contract COMPLETE
- [x] Capture task scope | Acceptance: `plan.md` states goal, scope, non-goals, assumptions, risks, and acceptance criteria.
- [x] Confirm worktree boundary | Acceptance: implementation occurs in `.worktrees/axiom-remove-never-sleep/` on `legion/axiom-remove-never-sleep-remove-inhibitor`.

## Phase 2: Implementation COMPLETE
- [x] Preserve Hypridle timing change | Acceptance: lock is 900 seconds and DPMS is 1800 seconds with matching comments.
- [x] Remove never-sleep implementation | Acceptance: `hosts/axiom/default.nix` has no generated script or user service for `axiom-caelestia-never-sleep`.
- [x] Update active docs/wiki | Acceptance: README and current wiki guidance no longer present the never-sleep service as active behavior.

## Phase 3: Verification COMPLETE
- [x] Run focused active-reference search | Acceptance: active config/docs have no `axiom-caelestia-never-sleep` current-behavior references.
- [x] Run diff whitespace check | Acceptance: `git diff --check` passes.
- [x] Run targeted Nix validation | Acceptance: Axiom config evaluates/builds or any environment limitation is recorded.

## Phase 4: Review And Delivery IN PROGRESS
- [x] Record review and walkthrough evidence | Acceptance: `docs/test-report.md`, `docs/review-change.md`, `docs/report-walkthrough.md`, and `docs/pr-body.md` exist.
- [ ] Complete PR lifecycle | Acceptance: branch pushed, PR created, auto-merge attempted, checks followed, terminal state recorded, worktree cleaned up, and main workspace refreshed.
