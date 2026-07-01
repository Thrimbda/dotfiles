# Report Walkthrough

Mode: implementation.

## Problem

`aliyun-acorn` still generated `/etc/ssh/authorized_keys.d/c1`, but the generated `sshd_config` no longer pointed sshd at `/etc/ssh/authorized_keys.d/%u`. The root cause was a host-level `services.openssh.extraConfig = lib.mkForce ""` override that cleared NixOS OpenSSH module-generated `extraConfig`, including `AuthorizedKeysFile`.

## Change

- Removed the shared `GSSAPIAuthentication no` `services.openssh.extraConfig` line from `modules/services/ssh.nix`.
- Removed the `aliyun-acorn` host override that forced all OpenSSH `extraConfig` to an empty string.
- Kept `aliyun-acorn` on non-socket-activated sshd through `startWhenNeeded = lib.mkForce false`.

## Why This Is Minimal

The patch fixes the source of the regression instead of re-adding `AuthorizedKeysFile` as another host-specific manual line. NixOS can once again emit its own OpenSSH-generated configuration while the unsupported `GSSAPIAuthentication no` line remains absent.

## Verification

Evidence: `docs/test-report.md`.

- Built `nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/sshd_config".source`.
- Confirmed the generated file contains `AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u`.
- Confirmed `GSSAPIAuthentication` is absent from the generated file.
- Confirmed `environment.etc."ssh/authorized_keys.d/c1"` still exists.
- `git diff --check` passed.

## Review

Evidence: `docs/review-change.md`.

- Result: PASS.
- Blocking findings: none.
- Security lens applied because SSH authentication configuration changed.
- Residual gap: remote deployment/restart and full system toplevel build were intentionally skipped for this repository-only fix.

## Files To Review

- `modules/services/ssh.nix`
- `hosts/aliyun-acorn/default.nix`
- `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/**`
