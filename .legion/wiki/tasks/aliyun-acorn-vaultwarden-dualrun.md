# Aliyun Acorn Vaultwarden Dual Run

Status: ready for PR

## Summary

Adds a staged Vaultwarden deployment configuration to `aliyun-acorn` while leaving the existing `acorn` deployment intact. The task creates a host-local `aliyun-acorn` Vaultwarden module, imports it from the target host, declares a target-host agenix secret rule, and adds a newly encrypted `vaultwarden-env.age` for the `aliyunAcorn` recipient.

## Current Shape

- `acorn` remains unchanged and still owns its existing Vaultwarden deployment.
- `aliyun-acorn` now imports `hosts/aliyun-acorn/modules/vaultwarden.nix`.
- `aliyun-acorn` exposes the same `vault.0xc1.space` service shape: Vaultwarden on local port `8000`, websocket hub on `3012`, nginx SSL/ACME vhost, and `/backup/vaultwarden` tmpfiles rules.
- `hosts/aliyun-acorn/secrets/vaultwarden-env.age` is encrypted for the existing `aliyunAcorn` key, and decryptability was checked with `/home/c1/.ssh/id_ed25519` without printing plaintext.

## Reusable Decisions

- For staged host migration of an agenix-backed service, do not copy an old `.age` file unless the target host can decrypt it. Re-encrypt using the source host's valid decrypt identity and the target host's declared recipient.
- During Vaultwarden dual-run, repository config can prepare the second host, but DNS/ACME readiness and data ownership/migration remain separate operational cutover work.
- Prefer host-local duplication over a shared abstraction for the first secret-sensitive dual-run slice; refactor only after the target host behavior is proven.

## Verification

- Target secret decryptability passed with output redirected to `/dev/null`.
- Targeted Nix shape checks passed for Vaultwarden service settings, nginx routes, secret ownership/mode, fail2ban integration, and `acorn` still enabled.
- Post-staging plain `nix eval --impure .#...` checks passed.
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.
- `review-change` passed with security lens applied and no blocking findings.

## Operational Follow-up

- Deploy `aliyun-acorn` only after reviewing DNS routing and ACME readiness for `vault.0xc1.space`.
- After deploy, check `vaultwarden.service`, `nginx.service`, `fail2ban.service`, ACME certificate status, and `/run/agenix/vaultwarden-env` ownership.
- Avoid split traffic or data divergence unless a separate data migration/ownership plan is in place.

## Source Evidence

- Raw task: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/`
- RFC: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/rfc.md`
- RFC review: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/review-rfc.md`
- Test report: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/test-report.md`
- Change review: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/review-change.md`
- Walkthrough: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/report-walkthrough.md`
