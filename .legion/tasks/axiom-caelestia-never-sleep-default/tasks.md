# Axiom Caelestia Never Sleep Default - Tasks

## Quick Restore

**Current Stage**: PR Lifecycle
**Current Checkpoint**: Wiki writeback complete; commit and PR lifecycle next
**Progress**: 7/8 phases complete

---

## Phase 1: Brainstorm - DONE

- [x] Materialize stable follow-up contract | Acceptance: plan and tasks capture goal, problem, acceptance, assumptions, constraints, risks, scope, non-goals, design summary, and phases

## Phase 2: Design Gate - DONE

- [x] Write and review a short RFC for Axiom's Caelestia never-sleep default | Acceptance: RFC selects the minimal enforcement layer, rollback, and validation path

## Phase 3: Engineer - DONE

- [x] Implement the reviewed Axiom-local Caelestia/session sleep inhibitor wiring and docs | Acceptance: Axiom enables Caelestia Keep Awake and a session sleep inhibitor by default without restoring the old toggle system

## Phase 4: Verify Change - DONE

- [x] Run focused static/Nix validation and the strongest feasible Axiom build | Acceptance: test report records pass/fail evidence without triggering live sleep or suspend

## Phase 5: Review Change - DONE

- [x] Assess scope, correctness, and power/session safety | Acceptance: review records PASS or concrete blockers

## Phase 6: Report Walkthrough - DONE

- [x] Produce reviewer-facing summary and PR body | Acceptance: walkthrough and PR body exist

## Phase 7: Legion Wiki - DONE

- [x] Update durable current truth for Axiom sleep behavior | Acceptance: wiki reflects Caelestia Keep Awake plus the session sleep inhibitor as the current default

## Phase 8: PR Lifecycle - TODO

- [ ] Commit, push branch, create/track PR, cleanup, and refresh main workspace when possible | Acceptance: PR reaches terminal state or lifecycle outcome is recorded
