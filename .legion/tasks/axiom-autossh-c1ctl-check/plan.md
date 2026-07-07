# Axiom Autossh C1ctl Check

## Task ID
`axiom-autossh-c1ctl-check`

## Goal
Replace Axiom's periodic autossh endpoint systemd healthcheck with an on-demand `c1ctl` diagnostic command.

## Problem
The autossh endpoint check was implemented as a timer-backed systemd oneshot that ran about once per minute and restarted autossh after repeated failures. That is too aggressive for this tunnel's real operating model. The check is useful as a manual deployment/debugging diagnostic, but the periodic timer adds background SSH traffic and operational noise for little value.

## Acceptance
- Axiom no longer generates `autossh-reverse-ssh-healthcheck.service` or its timer.
- Cloudflared and Clash healthchecks remain intact.
- `c1ctl` exposes an on-demand command that verifies remote `127.0.0.1:2223` exposes Axiom's local ED25519 SSH host key.
- The `c1ctl` command uses the same remote user and service-specific known-hosts strategy as autossh: `c1@8.159.128.125`, generated remote host key pin, and no mutable user known-hosts dependency.
- `c1ctl` help/which surfaces include the new command.
- Axiom NixOS toplevel and the `c1ctl` package build successfully.
- A live smoke of the command either passes or records the runtime precondition that the tunnel must already be active.

## Scope
- Remove only the Axiom autossh endpoint healthcheck instance from systemd.
- Leave the generic healthchecks module available for other checks.
- Add the manual autossh endpoint diagnostic to `packages/c1ctl`.
- Update Legion task/wiki evidence.

## Non-goals
- Do not remove cloudflared or Clash healthcheck timers.
- Do not change autossh service ownership, remote port, local port, bind address, or host-key pinning.
- Do not add a new daemon, timer, background process, or long-running monitor.
- Do not change remote host provisioning or SSH key material.

## Assumptions
- The current remote host remains `8.159.128.125` and the intended remote user remains `c1`.
- The remote `2223` endpoint is only expected to pass when `autossh-reverse-ssh.service` is active and the tunnel is established.
- `c1ctl` is an Axiom-local control CLI and can own this host-specific diagnostic.

## Constraints
- Use Legion workflow and isolated git worktree delivery.
- Keep the implementation minimal and dependency-free unless existing project structure requires otherwise.
- Preserve strict host-key validation for the remote SSH connection.

## Risks
- A manual command no longer provides automatic restart behavior; this is intentional because the timer was judged too noisy/low-value.
- A live command smoke can fail before deployment or when the tunnel is down; validation should still prove command behavior and report the runtime precondition clearly.

## Design Summary
Delete the Axiom autossh healthcheck entry so Nix no longer generates the autossh endpoint systemd service/timer. Keep generic healthcheck support for the remaining cloudflared and Clash checks. Add a built-in `c1ctl autossh check` command that shells out through controlled argv to `ssh`, `ssh-keyscan`, and `cut`, compares the remote endpoint ED25519 key to `/etc/ssh/ssh_host_ed25519_key.pub`, and returns non-zero on mismatch. This keeps the useful diagnostic while making it an explicit operator action rather than background automation.

## Phases
1. Materialize the Legion task contract.
2. Remove the autossh systemd healthcheck instance from Axiom.
3. Add the `c1ctl autossh check` diagnostic.
4. Validate generated NixOS config, package build, help/which behavior, and diagnostic behavior.
5. Review, produce walkthrough/PR evidence, write wiki updates, and deliver through PR.
