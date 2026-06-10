# Axiom Critical Network Resilience - Task List

## Quick Resume

**Current Phase**: Complete
**Current Checkpoint**: PR #79 merged; closeout PR records terminal state
**Progress**: 6/6 phases complete

---

## Phase 1: Contract COMPLETE

- [x] Create stable Legion task contract | Acceptance: `plan.md` and `tasks.md` define goal, scope, acceptance, assumptions, constraints, risks, and phases.

---

## Phase 2: Design COMPLETE

- [x] Produce focused RFC | Acceptance: RFC covers OOM/resource policy, health checks, rollback, verification, alternatives, and user-unit override uncertainty.
- [x] Review RFC | Acceptance: Review decides whether implementation can safely begin or returns required design changes.

---

## Phase 3: Implementation COMPLETE

- [x] Enter `git-worktree-pr` envelope | Acceptance: production config changes happen outside the shared main checkout.
- [x] Implement approved critical-network resilience changes | Acceptance: changes stay within approved scope and avoid persistent SSH host-key mutation.

---

## Phase 4: Verification COMPLETE

- [x] Run Nix build/eval and targeted service-shape checks | Acceptance: evidence written to `docs/test-report.md` or blockers recorded.
- [x] Run safe live checks on current services where applicable | Acceptance: active-but-broken conditions are checked without destructive stress testing.

---

## Phase 5: Review COMPLETE

- [x] Review implementation for scope, safety, and operational risk | Acceptance: `docs/review-change.md` records pass/fail and any residual risks.

---

## Phase 6: Delivery COMPLETE

- [x] Produce walkthrough and PR body | Acceptance: reviewer-facing summary and test evidence are available.
- [x] Update Legion wiki | Acceptance: current truth and reusable patterns are written back.
- [x] Complete PR lifecycle or record blocker | Acceptance: PR is merged/closed/blocked with worktree cleanup status documented.

---

## Discovered Follow-ups

(None yet.)
