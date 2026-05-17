# Axiom Remove Idle Suspend - Tasks

## Quick Restore
**Current Phase**: Delivery
**Current Checkpoint**: Open PR and follow lifecycle
**Progress**: 7/8 tasks complete

---

## Phase 1: Contract COMPLETE
- [x] Restore task scope | Acceptance: Goal, constraints, and success criteria are captured in `plan.md`.
- [x] Confirm target idle behavior | Acceptance: Lock and DPMS remain, automatic idle suspend is removed.

## Phase 2: Implementation COMPLETE
- [x] Remove Hypridle suspend trigger | Acceptance: `$suspend_cmd` and the 15 minute listener are removed from `config/hypr/hypridle.conf`.

## Phase 3: Verification COMPLETE
- [x] Run focused suspend-string grep | Acceptance: No automatic suspend strings remain in Hypridle config.
- [x] Run diff whitespace check | Acceptance: `git diff --check` passes.
- [x] Build Axiom toplevel | Acceptance: Nix toplevel build completes.

## Phase 4: Delivery IN PROGRESS
- [x] Record review and walkthrough evidence | Acceptance: `docs/review-change.md`, `docs/report-walkthrough.md`, and `docs/pr-body.md` exist.
- [ ] Complete PR lifecycle | Acceptance: Branch pushed, PR created, auto-merge attempted, checks followed, terminal state recorded, worktree cleaned up, main workspace refreshed.
