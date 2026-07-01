# aliyun-acorn sshd AuthorizedKeysFile Fix

## Contract

`aliyun-acorn` currently generates `/etc/ssh/authorized_keys.d/c1`, but its generated `sshd_config` does not contain an `AuthorizedKeysFile` directive. The immediate cause is the host-level override `services.openssh.extraConfig = lib.mkForce ""`, which removes NixOS OpenSSH module-generated lines, including `AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u`.

## Goal

Restore `aliyun-acorn` SSH public-key authentication through `/etc/ssh/authorized_keys.d/c1` while preserving the previous intent of avoiding the unsupported inherited `GSSAPIAuthentication no` line.

## Acceptance

- Evaluating `nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/sshd_config".source` yields a generated config that contains `AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u`.
- The generated `sshd_config` for `aliyun-acorn` does not contain `GSSAPIAuthentication no`.
- `nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/authorized_keys.d/c1"` still exists and points at generated c1 keys.
- The fix is minimal and does not change unrelated host services, firewall rules, user keys, or deployment secrets.

## Scope

- Adjust dotfiles Nix configuration for OpenSSH behavior.
- Verify Nix evaluation/build-level SSH configuration for `aliyun-acorn`.
- Record implementation, verification, review, walkthrough, and wiki writeback evidence.

## Non-Goals

- Do not rotate SSH host keys or user authorized keys.
- Do not deploy to the remote host in this task unless explicitly requested later.
- Do not redesign cloud-init, fail2ban, frp, nginx, or vaultwarden configuration.
- Do not change OpenSSH authentication policy beyond restoring the intended authorized-keys file path.

## Assumptions

- `azar` in user discussion maps to `hosts/aliyun-acorn` and `nixosConfigurations.aliyun-acorn`.
- The previous `extraConfig = lib.mkForce ""` was added only to suppress inherited `GSSAPIAuthentication no` on this host.
- NixOS 25.11 currently emits important OpenSSH defaults through `services.openssh.extraConfig`, so forcing it empty is too broad.

## Constraints

- Use Legion workflow for task documentation and closing evidence.
- Use the git worktree PR envelope for repository modifications.
- Keep the patch as small as possible.

## Risks

- A global removal of inherited `GSSAPIAuthentication no` may affect other hosts' generated `sshd_config`, but the option is unsupported by the currently evaluated OpenSSH package and has already caused logs on `aliyun-acorn`.
- If another host relied on the literal extraConfig line for policy, removal changes generated config there; verification should at least evaluate the target host and keep the change narrowly justified.

## Recommended Direction

Remove the inherited `GSSAPIAuthentication no` from the shared SSH module instead of forcing `aliyun-acorn`'s entire `services.openssh.extraConfig` to empty. Then remove the host-level `extraConfig` override so NixOS can emit its own OpenSSH module lines, including `AuthorizedKeysFile`.

## Phases

1. Stabilize contract and create Legion task docs.
2. Open a git worktree PR envelope.
3. Implement the minimal Nix config change.
4. Verify generated `aliyun-acorn` SSH configuration.
5. Run readiness review.
6. Write walkthrough and wiki summary.
