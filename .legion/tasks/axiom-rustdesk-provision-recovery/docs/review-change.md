# Change Review: Axiom RustDesk Provision Recovery

> **Review type**: Correctness, scope, and security
> **Status**: PASS for merge; post-merge runtime gate remains required
> **Date**: 2026-08-20

## Blocking Findings

None.

## Scope Review

- The sole production diff is `hosts/axiom/modules/rustdesk.nix`.
- The remaining additions are task-local design, verification, and review
  evidence under `.legion/tasks/axiom-rustdesk-provision-recovery/`.
- No encrypted `.age` files, RustDesk topology, client package, finalizer, or
  unrelated host configuration changed.

## Correctness Review

- `remove_revision_object` mirrors the established ready-object deletion
  discipline: canonical inspection, expected-state assertion, unlink, directory
  sync, reinspection, and an `absent` postcondition.
- Preflight now distinguishes durable successful pending state from incomplete
  state. A valid `ready=current` exits without invoking the password flow;
  `ready=absent|stale` can only clear a validated `attempt=current` and then
  follows the existing provision sequence.
- Invalid reservation or ready objects continue to fail through existing
  inspectors. The `stamp=current` fast path is unchanged.
- Including `rustdeskProvision` in `restartTriggers` is narrowly scoped: a
  code change causes the oneshot to run on switch, while a current stamp remains
  a no-op and avoids a needless password replay.
- The generated script and generated unit match the source decision, and the
  Axiom closure built successfully. See `test-report.md` for exact evidence.

## Security Review

**Security lens applied** because the root service handles an encrypted
permanent password and persistent state.

- No new secret read, log output, store embedding, process recipient, or
  plaintext task artifact was introduced.
- State deletion remains limited to a root-owned, non-symlink, exact-current
  reservation while the existing operation lock is held.
- The new retry may reissue the same configured password after an uncertain
  interrupted run. This is the explicit user-selected recovery policy; it does
  not broaden password input or trust boundaries.
- The explicit `rustdesk-provision-finalize --confirm-remote-auth` gate remains
  unchanged. A ready record is not converted into a stamp automatically.

## Residual Risk And Required Gate

- Static/build evidence cannot observe the mutable state combination present on
  the live host. After merge, an interactive privileged Axiom switch must prove
  that `rustdesk-provision.service` no longer fails with `attempt-used`.
- This residual is an operational acceptance gate, not a source-review blocker:
  the exact generated transition and restart trigger have already been built
  and inspected.

## Decision

**PASS for merge.** Proceed through PR delivery, then complete the documented
post-merge Axiom switch and service-status check before declaring the incident
fully resolved.
