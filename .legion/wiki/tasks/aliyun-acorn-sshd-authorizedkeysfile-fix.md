# Aliyun Acorn sshd AuthorizedKeysFile Fix

Status: ready for PR

## Summary

Restores `aliyun-acorn` SSH public-key authentication through `/etc/ssh/authorized_keys.d/c1`. The host was still generating `ssh/authorized_keys.d/c1`, but its generated `sshd_config` lacked `AuthorizedKeysFile` because `services.openssh.extraConfig = lib.mkForce ""` cleared NixOS OpenSSH module-generated `extraConfig`.

## Current Shape

- `modules/services/ssh.nix` no longer injects `GSSAPIAuthentication no` through shared OpenSSH `extraConfig`.
- `hosts/aliyun-acorn/default.nix` no longer forces OpenSSH `extraConfig` to an empty string.
- `aliyun-acorn` keeps `services.openssh.startWhenNeeded = lib.mkForce false`, so SSH remains a normal daemon service rather than socket activated.
- NixOS-generated `sshd_config` again includes `AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u`.
- `environment.etc."ssh/authorized_keys.d/c1"` still materializes the generated c1 authorized keys file.

## Reusable Pattern

- Do not use a broad `mkForce ""` override on `services.openssh.extraConfig` to remove one inherited OpenSSH line. Remove the problematic source line instead, because NixOS also emits generated `sshd_config` directives through that same channel.
- For SSH auth regressions, validate both the generated `sshd_config` line and the generated `/etc/ssh/authorized_keys.d/<user>` entry. Either side alone is insufficient.

## Verification

- Built `nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/sshd_config".source` and confirmed it contains `AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u`.
- Confirmed `GSSAPIAuthentication` is absent from the generated `sshd_config`.
- Confirmed `environment.etc."ssh/authorized_keys.d/c1"` exists.
- `git diff --check` passed.
- `review-change` passed with security lens applied and no blocking findings.

## Follow-Up

- Remote deployment/restart was not performed in this task.
- A full target toplevel build or `sshd -t` against the generated config can be used as stronger pre-deploy evidence if needed.

## Source Evidence

- Raw task: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/`
- Test report: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/docs/test-report.md`
- Change review: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/docs/review-change.md`
- Walkthrough: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/docs/report-walkthrough.md`
