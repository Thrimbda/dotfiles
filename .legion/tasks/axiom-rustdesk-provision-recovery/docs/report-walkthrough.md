# Delivery Walkthrough: Axiom RustDesk Provision Recovery

> **Mode**: implementation
> **Source status**: Merged in PR #182
> **Operational status**: PASS

## What Changed

- Replaced the terminal `attempt-used` branch in Axiom's RustDesk provisioner.
- A valid current `attempt` with `ready=absent|stale` is now removed through the
  existing canonical-state safety pattern and retried by the established flow.
- A valid current `attempt` with `ready=current` exits successfully without
  resetting the password and preserves manual remote-auth finalization.
- Added the generated provision script to `restartTriggers`, ensuring a source
  update invokes the new state machine on the next NixOS switch without changing
  the persistent revision or reprocessing a valid final stamp.

## Why This Is Safe

- The removal helper validates the root-owned regular file before and after its
  deletion and operates under the pre-existing `flock`.
- Invalid state still fails through the existing inspectors.
- The encrypted password path, password invocation boundary, and explicit
  `rustdesk-provision-finalize --confirm-remote-auth` process are unchanged.
- The review explicitly applied the security lens for root state and secret
  handling. See `review-change.md`.

## Evidence

- RFC heavy design review: PASS, including a resolved fast-path scope finding.
- Axiom toplevel evaluation: PASS.
- Axiom no-link closure build: PASS; 31 candidate derivations realized.
- Generated provision script: `bash -n` PASS and recovery branches inspected.
- Generated systemd unit: `systemd-analyze verify` PASS.
- Generated restart-trigger artifact includes the candidate provision script.
- Post-merge Axiom switch: deployed unit ran the candidate script and exited
  `0/SUCCESS` with no new `attempt-used` journal entry.

Full commands, paths, and evidence limits are in `test-report.md`.

## Runtime Outcome

The user-authorized Axiom switch deployed merged `origin/master`. The provision
unit executed `/nix/store/6f8i8gqizkw2v7nx9v36h75qi9z2l3b6-axiom-rustdesk-provision`
and completed `0/SUCCESS` at `2026-08-21 11:45:25 CST`; the bounded journal has
no `attempt-used` record for that invocation. The finalizer was not run and
continues to require real remote-auth confirmation.

## Rollback

Revert this source change and switch Axiom again if the new recovery transition
misbehaves. That restores the prior fail-stop policy; it does not authorize
manual deletion of invalid state.
