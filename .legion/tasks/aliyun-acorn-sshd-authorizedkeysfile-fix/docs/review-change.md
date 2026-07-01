# Review Change

## Result

PASS.

## Blocking Findings

None.

## Security Lens

Applied. SSH authentication configuration is security-sensitive.

## Review Notes

- Correctness: the diff removes only the broad `services.openssh.extraConfig = lib.mkForce ""` override in `hosts/aliyun-acorn/default.nix` and the inherited unsupported `GSSAPIAuthentication no` line from `modules/services/ssh.nix`.
- Scope: changes are limited to expected SSH config files plus Legion task docs. No unrelated services, firewall rules, user keys, or secrets changed.
- Verification: `docs/test-report.md` records the required evidence: generated `sshd_config` contains the exact `AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u` line, `GSSAPIAuthentication` is absent, `/etc/ssh/authorized_keys.d/c1` still exists, and `git diff --check` passed.
- Maintainability/security: the fix removes an overly broad force override instead of layering more host-specific SSH config. This is safer and easier to reason about.

## Non-Blocking Suggestions

- Before deployment, a full target toplevel build or `sshd -t` against the generated config would provide stronger end-to-end confidence.

## Residual Risks

- Remote deployment/restart was intentionally skipped.
- Full system toplevel build was not run; evidence is targeted to the SSH config regression and is sufficient for this contract.
