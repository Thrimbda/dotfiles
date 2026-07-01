# Log

## 2026-07-02

- Diagnosed `aliyun-acorn` SSH issue: `services.openssh.authorizedKeysFiles` still evaluates to `%h/.ssh/authorized_keys` and `/etc/ssh/authorized_keys.d/%u`, and `/etc/ssh/authorized_keys.d/c1` is generated, but the generated `sshd_config` lacks the `AuthorizedKeysFile` line.
- Root cause is the host-level `services.openssh.extraConfig = lib.mkForce ""`, which clears NixOS OpenSSH module-generated `extraConfig`, including `AuthorizedKeysFile`.
- Created Legion task contract for a minimal fix: remove inherited unsupported `GSSAPIAuthentication no` at the shared source and stop forcing the host `extraConfig` empty.
- Opened worktree `.worktrees/aliyun-acorn-sshd-authorizedkeysfile-fix` on branch `legion/aliyun-acorn-sshd-authorizedkeysfile-fix-ssh` from `origin/master`.
- Implemented the minimal config change: removed the shared `services.openssh.extraConfig = ''GSSAPIAuthentication no''` line and removed the `aliyun-acorn` `extraConfig = lib.mkForce ""` override.
- Verification passed: built `nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/sshd_config".source`, confirmed the expected `AuthorizedKeysFile` line is present, confirmed `GSSAPIAuthentication` is absent, confirmed `ssh/authorized_keys.d/c1` remains generated, and `git diff --check` passed.
- Readiness review passed with security lens applied; no blocking findings. Residual gap: remote deployment/restart and full target toplevel build were intentionally skipped.
- Wrote implementation-mode walkthrough and PR body under `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Completed wiki writeback: added task summary and OpenSSH `extraConfig` validation pattern.
