# Axiom Caelestia Keep Awake Default - Tasks

## Quick Restore

**Current Stage**: PR Lifecycle
**Current Checkpoint**: Commit, push branch, create/track PR, cleanup, and refresh main workspace when possible
**Progress**: 6/7 phases complete

---

## Phase 1: Brainstorm - DONE

- [x] Materialize stable follow-up contract | Acceptance: plan and tasks capture goal, scope, acceptance, assumptions, risks, non-goals, and design-lite

## Phase 2: Engineer - DONE

- [x] Replace custom no-sleep wiring with Caelestia Keep Awake startup enablement | Acceptance: Axiom uses `caelestia shell idleInhibitor enable` and removes custom wrapper/service/launcher no-sleep layer

## Phase 3: Verify Change - DONE

- [x] Run targeted Nix/static checks and Axiom build | Acceptance: test report records pass/fail evidence without triggering sleep/hibernate

## Phase 4: Review Change - DONE

- [x] Assess scope, correctness, and session/power safety | Acceptance: review records PASS or concrete blockers

## Phase 5: Report Walkthrough - DONE

- [x] Produce PR-ready summary | Acceptance: walkthrough and PR body exist

## Phase 6: Legion Wiki - DONE

- [x] Update current decisions/patterns/maintenance | Acceptance: wiki marks Caelestia Keep Awake as current truth and supersedes the custom wrapper

## Phase 7: PR Lifecycle - IN PROGRESS

- [ ] Commit, push branch, create/track PR, cleanup, and refresh main workspace when possible | Acceptance: PR reaches terminal state and lifecycle outcome is recorded
