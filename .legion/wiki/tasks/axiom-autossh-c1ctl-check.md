# Axiom Autossh C1ctl Check

## Metadata

- `task-id`: `axiom-autossh-c1ctl-check`
- `status`: `ready-for-deploy`
- `risk`: `medium`
- `schema-version`: `2026-07-05-legion-workflow`
- `historical`: `false`
- `supersedes`: `axiom-autossh-c1-runtime-fix` autossh endpoint healthcheck delivery mechanism
- `superseded-by`: `(none)`

## Outcome Summary

Axiom no longer generates the periodic `autossh-reverse-ssh-healthcheck` systemd service/timer. The autossh endpoint identity check is now an explicit operator command: `c1ctl autossh check`.

The command uses Axiom's Nix-injected reverse-ssh remote host/user/port/host-key values, creates a temporary service-specific known-hosts file, SSHes to `c1@8.159.128.125`, scans remote `127.0.0.1:2223`, and compares the exposed ED25519 key with Axiom's local `/etc/ssh/ssh_host_ed25519_key.pub`.

## Reusable Decisions

- Autossh endpoint identity validation on Axiom is on-demand through `c1ctl autossh check`, not timer-driven systemd automation.
- Cloudflared and Clash healthchecks remain timer-backed because they still represent local service readiness/core checks.
- `c1ctl` host-specific network diagnostics should receive fixed endpoint values from Nix rather than duplicating mutable literals in Rust.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-autossh-c1ctl-check/plan.md`
- `log`: `.legion/tasks/axiom-autossh-c1ctl-check/log.md`
- `tasks`: `.legion/tasks/axiom-autossh-c1ctl-check/tasks.md`
- `test-report`: `.legion/tasks/axiom-autossh-c1ctl-check/docs/test-report.md`
- `change-review`: `.legion/tasks/axiom-autossh-c1ctl-check/docs/review-change.md`
- `report`: `.legion/tasks/axiom-autossh-c1ctl-check/docs/report-walkthrough.md`
