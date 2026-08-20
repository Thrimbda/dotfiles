# Delivery Walkthrough: Axiom RustDesk Provision Recovery

> **Mode**: implementation
> **Source status**: Ready for merge
> **Operational status**: Post-merge switch required

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

Full commands, paths, and evidence limits are in `test-report.md`.

## Required After Merge

1. Refresh Axiom to merged `origin/master`.
2. Run the normal privileged `nixos-rebuild switch --flake .#axiom` flow.
3. Confirm `rustdesk-provision.service` no longer reports `attempt-used` and the
   overall switch does not fail because of that unit.
4. Do not run the finalizer unless a real remote authentication confirmation has
   occurred.

## Rollback

Revert this source change and switch Axiom again if the new recovery transition
misbehaves. That restores the prior fail-stop policy; it does not authorize
manual deletion of invalid state.
