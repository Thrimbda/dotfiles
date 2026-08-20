# RFC: Axiom RustDesk Provision Recovery

> **Profile**: RFC Heavy
> **Status**: Approved
> **Owner**: OpenCode
> **Created**: 2026-08-20
> **Last Updated**: 2026-08-20

## Executive Summary

- **Problem**: A current `attempt` marker becomes a permanent activation
  failure after an interrupted provision run.
- **Decision**: Clear only a validated current attempt when no current ready
  proof exists, then use the existing provisioning sequence to retry.
- **Ready state**: A validated current `ready-to-finalize` record exits
  successfully and remains available for explicit remote-auth finalization.
- **Impact**: A failed provision can recover on the next Axiom activation
  without weakening validation or exposing the permanent password.
- **Rollout**: Merge, evaluate/build, then switch Axiom and observe the
  provision service's successful completion.
- **Rollback**: Revert the source change and switch again if the new state
  transition fails; this restores the previous fail-stop behavior.

## 1. Context And Evidence

The provisioner writes `attempt` after public configuration succeeds and before
it reads the agenix secret or invokes `rustdesk --password`. It publishes
`ready-to-finalize` only after password application, a RustDesk restart, and
runtime identity verification. The preflight branch currently rejects a current
attempt with `ready=absent|current` as `attempt-used`.

The reported activation took that branch. The failure is deterministic on every
later activation because the state is never consumed or retried.

## 2. Goals

- Recover automatically from a canonical interrupted attempt.
- Preserve root-only secret handling, state validation, locking, runtime
  verification, and manual remote-auth finalization.
- Keep malformed or contradictory state inspected by recovery fail-closed.
- Avoid reapplying the password on hosts whose current revision is already
  finalized with a `stamp`.

## 3. Non-goals

- Change RustDesk topology, client version, capture behavior, or password
  policy.
- Change the encrypted secret or log any secret material.
- Automatically invoke the remote-auth finalizer.
- Add a generic RustDesk test framework or repair unrelated session failures.

## 4. Constraints

- Mutations must happen after the existing root-held operation lock and only
  against objects accepted by `inspect_revision_object` or
  `inspect_ready_object`.
- The state format and revision prefix remain unchanged. The recovery code does
  not require a data migration.
- Do not bump `provision=axiom-rustdesk-provision-v8` solely for this logic.
  A bump would make every valid stamped v8 installation stale and needlessly
  reapply its permanent password.
- Add the provision-script derivation to `rustdesk-provision.restartTriggers`.
  This gives a script update an explicit system-switch activation path while a
  valid current stamp still takes the existing no-op fast path.

## 5. Definitions

- **stamp**: A revision object published only after explicit remote-auth
  finalization; it is the terminal fast-path proof.
- **attempt**: A revision object reserving an in-progress password provision.
- **ready**: A structured runtime proof published after the password operation;
  it remains pending until the operator confirms remote authentication.
- **current**: The object is canonical and byte-identical to the active
  revision. **stale** is canonical but for another revision.

## 6. Proposed Design

### State Transitions

| `stamp` | `attempt` | `ready` | Action |
| --- | --- | --- | --- |
| current | any | any | Preserve the existing terminal fast path and exit successfully, unchanged. |
| absent or stale | current | current | Exit successfully, unchanged; manual finalization remains available. |
| absent or stale | current | absent | Remove the validated current attempt, then run the existing provision flow. |
| absent or stale | current | stale | Remove the validated current attempt, then run the existing stale-ready cleanup and provision flow. |
| absent or stale | absent or stale | absent or stale | Preserve the existing provision flow. |
| absent or stale | invalid | any | Fail closed through the existing reservation inspector. |
| absent or stale | absent, stale, or current | invalid | Fail closed through the existing ready inspector. |
| absent or stale | absent or stale | current | Preserve the existing contradictory-state failure. |

### Implementation Shape

Add a narrowly scoped revision-object removal helper beside the existing
publisher. It must inspect the target, require the requested state, unlink it,
sync the state directory, reinspect it, and require `absent`.

At preflight, replace the terminal `attempt-used` branch:

- `ready=current`: return success without changing state.
- `ready=absent|stale`: remove only a validated `attempt=current`, update the
  local reservation state to `absent`, and continue through the established
  provision sequence.
- Any inspector error or unrecognized combination remains a named failure.

The existing stale-ready removal after publishing the new reservation remains
the sole place that removes a valid stale ready record.

Add `rustdeskProvision` to the service `restartTriggers` beside the encrypted
secret and revision object. The derivation path changes with the recovery code,
so NixOS restarts the oneshot during a switch even though the persistent
revision deliberately remains v8.

## 7. Alternatives Considered

### Option A: Validated recovery and retry (selected)

- **Pros**: Repairs incomplete work automatically, keeps invalid state
  fail-closed, and preserves the ready/finalize boundary.
- **Cons**: An uncertain prior post-password failure can run the same password
  operation once more.
- **Mitigation**: The retry uses the same protected secret and only follows a
  canonical state inspection under the existing lock.

### Option B: Treat `attempt-used` as success

- **Pros**: Stops `nixos-rebuild` from failing.
- **Cons**: Leaves a pre-password failure permanently unresolved and misreports
  provision success.
- **Decision**: Rejected because it violates the requested automatic recovery.

### Option C: Bump the provisioning revision only

- **Pros**: The currently failed attempt becomes stale and the existing code
  retries it once.
- **Cons**: The next interruption fails again, and all current stamps become
  stale and reapply their password.
- **Decision**: Rejected as a one-time workaround with unnecessary impact.

### Option D: Require manual state deletion

- **Pros**: No changed automatic behavior.
- **Cons**: Root-only manual repair remains necessary after every interruption
  and recreates the same operational failure mode.
- **Decision**: Rejected by the selected recovery policy.

## 8. Migration, Rollout, And Rollback

### Migration

No schema migration is needed. On the first execution of the new script, a
validated incomplete attempt is consumed and retried. Existing final stamps and
valid pending ready records are retained.

### Rollout

1. Run the documented source checks and inspect the generated provision script.
2. Merge the PR and refresh the main worktree to the merged baseline.
3. Run the normal Axiom `nixos-rebuild switch --flake .#axiom` flow.
4. Confirm `rustdesk-provision.service` is successful and the journal does not
   contain `attempt-used`.
5. If a ready marker remains pending, retain the existing explicit
   `rustdesk-provision-finalize --confirm-remote-auth` workflow after a real
   remote-auth confirmation.

### Rollback

If the new recovery path fails or changes behavior outside this RFC, revert the
PR and switch Axiom to the prior configuration. This restores the old
fail-stop behavior; a valid incomplete attempt may then require operator repair
instead of automatic recovery. Do not delete invalid state as part of rollback.

## 9. Observability

- Success remains the normal silent oneshot completion with systemd state as the
  primary signal.
- Named failures continue to identify the failing guard, including a new
  reservation-reset failure if state cleanup cannot be proven safe.
- Post-switch evidence is `systemctl status rustdesk-provision.service` and
  bounded `journalctl -u rustdesk-provision.service` output without secret data.

## 10. Security And Privacy

- The permanent password remains read only from the root-owned agenix target.
- The recovery helper uses the same canonical-file checks as publication before
  deleting a state object; it does not follow symlinks or relax mode checks in
  the recovery path. The existing `stamp=current` terminal fast path remains
  unchanged.
- The operation lock remains held throughout inspection, removal, password use,
  restart, and ready publication.
- No additional process receives the password, and no state payload is copied
  into logs or task artifacts.

## 11. Verification Strategy

- Inspect the source diff for the exact state transition and absence of the
  terminal `attempt-used` path.
- Evaluate the Axiom toplevel derivation and run a no-link Axiom system build.
- Inspect the built `ExecStart` script and run shell syntax validation without
  executing RustDesk or reading the secret.
- Confirm the live current failure recovers after the merged switch.
- Record that static validation cannot prove all RustDesk/session timing paths;
  any remaining runtime failure must retain its named failure status.

## 12. Milestones

- **Milestone 1: Design gate**
  - Scope: Research, RFC, and adversarial design review.
  - Acceptance: The transition table, rollback, and secret boundary pass review.
- **Milestone 2: Source change and static validation**
  - Scope: Minimal provisioner state-machine change plus generated-script checks.
  - Acceptance: The source and built output implement only the approved paths.
- **Milestone 3: Delivery and recovery activation**
  - Scope: PR lifecycle, merged Axiom switch, and service-status evidence.
  - Acceptance: The currently blocked activation no longer ends in `attempt-used`.

## 13. Open Questions

- None block the implementation. Privileged inspection of the old state file is
  useful after deployment but not required to distinguish the safe transitions.

## 14. Implementation Notes

- Expected source file: `hosts/axiom/modules/rustdesk.nix`.
- Add no package, service, secret, or state-schema dependency.
- Preserve `ready=current` for manual finalization rather than publishing a
  stamp automatically.

## 15. References

- Task contract: `../plan.md`
- Research: `research.md`
- Provisioner: `hosts/axiom/modules/rustdesk.nix:189-897`
- Historical state boundary: `.legion/wiki/tasks/axiom-rustdesk-fixed-dp4-capture.md`
