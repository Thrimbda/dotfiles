# Axiom Autossh C1 Runtime Fix

## Task ID
`axiom-autossh-c1-runtime-fix`

## Goal
Restore Axiom's autossh reverse SSH runtime path so the generated service and healthcheck connect to `c1@8.159.128.125` and are not blocked by stale user-level host-key entries.

## Problem
The live `autossh-reverse-ssh.service` is active only as an autossh supervisor and repeatedly fails to establish the SSH tunnel. Diagnostics showed two blockers: the generated unit still targets `root@8.159.128.125`, while the redeployed remote host accepts Axiom's key for `c1`; and service OpenSSH reads `/home/c1/.config/ssh/known_hosts`, whose `8.159.128.125` entry still contains the pre-redeploy host key. As a result, autossh fails strict host-key checking before it can authenticate, and would still fail authentication if the stale key were fixed without changing the remote user.

## Acceptance
- `autossh-reverse-ssh.service` generates an ExecStart targeting `c1@8.159.128.125`.
- The reverse tunnel remains `127.0.0.1:2223:127.0.0.1:22`.
- The autossh endpoint-key healthcheck connects as the same remote user as the service.
- Service-owned SSH invocations for autossh and its healthcheck use a task-specific generated known-hosts file and do not depend on stale `~/.config/ssh/known_hosts` entries.
- A focused Nix eval confirms the service command and healthcheck runner use `c1`.
- The Axiom NixOS toplevel build passes.
- Runtime smoke after activation proves remote `127.0.0.1:2223` exposes Axiom's local SSH host key, or any remaining activation blocker is recorded.

## Scope
- Update Axiom host configuration for the reverse SSH remote account and a service-specific SSH host-key source.
- Update the autossh healthcheck path only as needed to stay aligned with the service path.
- Add Legion task evidence, validation report, review, walkthrough, and wiki writeback.

## Non-goals
- Do not change `charlie`, `azar`, or FRP tunnel ownership.
- Do not change remote port `2223`, local port `22`, or the remote loopback bind address.
- Do not relax `StrictHostKeyChecking` or remove host identity validation.
- Do not rotate Axiom SSH keys.
- Do not manage remote host provisioning beyond requiring remote `c1` to accept Axiom's existing key.

## Assumptions
- The redeployed remote host key fingerprint `SHA256:/FJjQ7l4hZdaroHRdI9pi6oj5W3SfAJ+U6TrbjTzbeU` is the intended `8.159.128.125` ED25519 key.
- Remote user `c1` exists and currently accepts Axiom's `/home/c1/.ssh/id_ed25519` key.
- The local Axiom SSH daemon remains the intended tunnel target at `127.0.0.1:22`.

## Constraints
- Use the Legion workflow and the isolated git worktree envelope.
- Keep the fix minimal and Axiom-scoped.
- Preserve strict host-key validation while avoiding stale mutable user known-hosts state for this system service.
- Do not touch unrelated untracked files in the main checkout.

## Risks
- Live activation requires sudo on Axiom; repo validation can prove generated configuration but not switch it into the running system without authorization.
- If the remote host is redeployed again, the configured host-key source must be refreshed again.
- If remote `c1` loses the authorized key, autossh will fail with `Permission denied (publickey)` even after this config fix.

## Design Summary
Keep the existing reverse SSH tunnel design, but make the service path explicit: Axiom's reverse-ssh module instance should use remote user `c1`, and the autossh healthcheck should inherit that same value. To avoid mutable stale user host-key entries blocking a system service, the service and healthcheck should use a service-specific known-hosts file generated from the pinned remote key, rather than depending on `/home/c1/.config/ssh/known_hosts` or repinning the host globally in `/etc/ssh/ssh_known_hosts`. This preserves strict checking and avoids widening network exposure.

## Phases
1. Materialize the follow-up task contract.
2. Implement the Axiom autossh remote-user and known-hosts fix.
3. Validate generated service shape, healthcheck shape, build, and runtime smoke where possible.
4. Review the change for correctness, scope, and SSH security posture.
5. Produce walkthrough/PR evidence and update the Legion wiki.
