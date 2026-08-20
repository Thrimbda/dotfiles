# Research: Axiom RustDesk Provision Recovery

> **Profile**: RFC Heavy research
> **Date**: 2026-08-20

## Problem Restatement

- Axiom activation fails because a prior RustDesk provision run left a valid
  `attempt` marker. The next run reports `attempt-used` instead of recovering.
- The affected boundary is the root-owned persistent state under
  `/var/lib/rustdesk-provision`; no secret material needs to change.

## Relevant Code And Entry Points

- `hosts/axiom/modules/rustdesk.nix:189-897` defines the provisioner.
- `rustdesk.nix:259-313` validates and atomically publishes revision objects.
- `rustdesk.nix:315-483` validates and publishes the post-password
  `ready-to-finalize` proof.
- `rustdesk.nix:744-770` rejects a current `attempt` with either absent or
  current `ready` as `attempt-used`.
- `rustdesk.nix:789-895` writes `attempt` before the password command and
  writes `ready` only after restart and runtime validation. Therefore a failure
  between those operations leaves the observed recoverable state.
- `rustdesk.nix:898-1286` provides the separate, explicit
  `rustdesk-provision-finalize --confirm-remote-auth` workflow. A current
  `ready` is intentionally not equivalent to the final `stamp`.
- `rustdesk.nix:1360-1375` declares a root `oneshot` systemd service with a
  protected `StateDirectory` and `RemainAfterExit`.

## Evidence And Historical Context

- The activation log supplied for this task records
  `RustDesk provisioning failed: attempt-used` from the current generated
  provisioner.
- `.legion/wiki/tasks/rollout-auth-mini-audience-user-id.md` already records
  the same failure as an unrelated Axiom activation follow-up.
- `.legion/wiki/tasks/axiom-rustdesk-fixed-dp4-capture.md` requires permanent
  password state to remain root-owned and keeps only Wayland restore state
  writable by `c1`.
- The current module was introduced by `bf23cfb6`; blame attributes both the
  revision fingerprint and the terminal `attempt-used` branch to that change.

## Existing Conventions

- Persistent state is accepted only after type, non-symlink, ownership, mode,
  content, and revision checks.
- Every state mutation occurs while a root-held `flock` protects the state
  directory and is followed by a directory sync plus reinspection.
- Password input is resolved from an agenix file at runtime and is unset before
  later steps. It is not suitable for logs, task records, or synthetic fixtures.
- The NixOS manual documents `restartTriggers` as input to system-switch unit
  restart handling. A derivation-backed trigger gives the new provision script
  an explicit activation path without changing persisted state semantics.

## Risks And Pitfalls

- `attempt` can be left after a failure before or after the password command;
  the exact point is not available without privileged inspection of the live
  state. Reissuing the configured password is acceptable only after validating
  the marker and preserving the lock.
- A current `ready` proves the password-and-runtime path completed but still
  awaits the intentionally manual remote-auth confirmation. Retrying in that
  state would needlessly reset the password and blur the confirmation boundary.
- A stale `ready` cannot certify the current revision. It must retain the
  existing stale-object cleanup path rather than be treated as success.
- Invalid state must not be deleted opportunistically; it can represent a
  symlink, permission change, tampering, or truncation.

## Residual Trace

- **Observation**: `attempt-used` is emitted during a later activation.
- **Explained**: A current reservation is written before password application,
  while `ready` is written only after the later restart validation.
- **Residual**: The log alone cannot prove whether the prior run failed before
  or after applying the password.
- **Expansion**: Distinguish state that proves success (`ready=current`) from
  validated incomplete state (`attempt=current`, `ready=absent|stale`).
- **Closure**: The selected recovery is safe for both residual cases: preserve
  a valid ready proof, or retry the same configured password after removing
  only the validated reservation.

## Open Questions

- [ ] The live state file metadata could not be inspected non-interactively
  because `sudo -n` requires a password. This does not block the source fix;
  the emitted branch already constrains it to a valid current reservation.
- [ ] There is no dedicated provisioner state-machine test harness. Generated
  script checks and the live recovery activation cover the practical paths;
  adding a broad mock harness is outside this incident scope.

## References

- `../plan.md`
- `hosts/axiom/modules/rustdesk.nix`
- `.legion/wiki/tasks/rollout-auth-mini-audience-user-id.md`
- `.legion/wiki/tasks/axiom-rustdesk-fixed-dp4-capture.md`
- NixOS manual: systemd unit handling and `restartTriggers`
