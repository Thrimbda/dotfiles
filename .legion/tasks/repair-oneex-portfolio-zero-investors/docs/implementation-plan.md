# Implementation Plan

## Milestone 1: Design Gate

### Scope

- Review the historical event model and approve the bounded live repair design.

### Steps

- [ ] Confirm the RFC separates historical evidence from live preflight facts.
- [ ] Confirm no alternative introduces a fictional investment or broad history rewrite.

### Verification

- Expected: RFC review passes with exact event selection, deletion order, stop
  conditions, and zero-share NAV semantics.

### Rollback Notes

- No production mutation occurs.

## Milestone 2: Live Preflight

### Scope

- Inspect current Fund configuration, statement, source, NAV, investors, and
  event pages with a redacted owner session.

### Steps

- [ ] Identify the exact positive initial cash-flow event.
- [ ] Identify the matching owner-profile event.
- [ ] Verify no other financial event makes the deletion set ambiguous.

### Verification

- Expected: all preflight invariants from the RFC hold before any DELETE.

### Rollback Notes

- Stop with no mutation on any mismatch.

## Milestone 3: Bounded Repair

### Scope

- Remove the two approved artifacts, lock subscriptions, and capture one fresh
  Trading NAV sample.

### Steps

- [ ] Delete the live-verified cash-flow event.
- [ ] Re-read and verify reduced state before deleting the owner-profile event.
- [ ] Reassert private enabled Fund configuration with subscriptions closed.
- [ ] Take one fresh sample and verify final projection.

### Verification

- Expected: total assets equal sample equity, investor count and shares are
  zero, Funding Account contribution is zero, and subscriptions are closed.

### Rollback Notes

- Stop after any uncertain response; do not synthesize an inverse event.
