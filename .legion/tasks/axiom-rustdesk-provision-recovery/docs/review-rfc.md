# RFC Review: Axiom RustDesk Provision Recovery

> **Review type**: High-risk design gate
> **Status**: PASS
> **Date**: 2026-08-20

## Resolved Finding

### R1: The fail-closed claim overstates the existing terminal-state behavior

`rustdesk.nix:744-750` exits immediately when `stamp=current`; it does not
inspect `attempt` or `ready`. The draft acceptance and transition table claimed
that malformed state always fails closed, which is not true for unused side
objects after finalization. Making that claim true would require expanding the
runtime boundary of already-finalized installations and is outside this fix.

**Why it was blocking**: The implementation could otherwise add new inspections to the
terminal fast path and turn harmless post-finalization residue into an
activation failure, or reviewers could approve a verification claim the code
cannot establish.

**Resolution**: The contract and RFC now limit fail-closed behavior to objects
inspected by recovery, and explicitly preserve the existing `stamp=current`
fast path. The transition table and security section match that boundary.

## Non-blocking Notes

- Explicitly triggering the changed provision-script derivation is preferable
  to changing the persistent revision merely to force a retry.
- The RFC describes the helper's inspect-remove-sync-reinspect invariant and
  keeps stale-ready cleanup in the existing path, so the implementation can
  remain narrowly scoped.

## Decision

**PASS**. The high-risk design has a bounded state transition, explicit
alternatives, rollout/rollback, verification limits, and preserved secret and
manual-finalization boundaries. Implementation may proceed.
