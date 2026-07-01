## Summary

- Restore `aliyun-acorn` sshd reading `/etc/ssh/authorized_keys.d/%u` by removing the host override that cleared all OpenSSH `extraConfig`.
- Remove the inherited unsupported `GSSAPIAuthentication no` `extraConfig` at the shared SSH module source.
- Keep the fix limited to OpenSSH configuration and Legion evidence.

## Verification

- `src=$(nix build --no-link --print-out-paths '.#nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/sshd_config".source') && rg '^AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u$' "$src" && ! rg -q '^GSSAPIAuthentication\b' "$src"`
- `nix eval --json '.#nixosConfigurations.aliyun-acorn.config.environment.etc."ssh/authorized_keys.d/c1"'`
- `git diff --check`

## Legion Evidence

- Plan: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/plan.md`
- Test report: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/docs/test-report.md`
- Review: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/docs/review-change.md`
- Walkthrough: `.legion/tasks/aliyun-acorn-sshd-authorizedkeysfile-fix/docs/report-walkthrough.md`
