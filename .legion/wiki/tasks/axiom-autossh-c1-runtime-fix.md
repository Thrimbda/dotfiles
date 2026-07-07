# Axiom Autossh C1 Runtime Fix

## Metadata

- `task-id`: `axiom-autossh-c1-runtime-fix`
- `status`: `ready-for-deploy`
- `risk`: `medium`
- `schema-version`: `2026-07-05-legion-workflow`
- `historical`: `false`
- `supersedes`: `axiom-autossh-reverse-ssh-tunnel` remote account and host-key details for Axiom
- `superseded-by`: `axiom-autossh-c1ctl-check` for autossh endpoint healthcheck delivery mechanism

## Outcome Summary

Axiom's autossh reverse SSH configuration now targets `c1@8.159.128.125` instead of `root@8.159.128.125`. The service path also sets `GlobalKnownHostsFile` to a service-specific generated known-hosts file and `UserKnownHostsFile=/dev/null`. This prevents stale `/home/c1/.config/ssh/known_hosts` entries from blocking the system service while preserving strict host-key validation without repinning the host globally in `/etc/ssh/ssh_known_hosts`.

The reverse tunnel shape remains remote loopback `127.0.0.1:2223` to Axiom local `127.0.0.1:22`. Validation passed for generated service shape, Axiom toplevel build, service-style `c1` SSH authentication, and a temporary reverse endpoint identity smoke test. The timer-backed autossh healthcheck from this task was later replaced by the on-demand `c1ctl autossh check` command.

## Reusable Decisions

- Axiom's autossh tunnel to `8.159.128.125` uses remote account `c1`.
- Axiom's autossh service should not depend on mutable user known-hosts state; it uses `UserKnownHostsFile=/dev/null` with a service-specific generated known-hosts file. Endpoint identity is checked manually with `c1ctl autossh check`.
- Remote host redeploys require refreshing the pinned ED25519 key and validating both remote login and reverse endpoint identity.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-autossh-c1-runtime-fix/plan.md`
- `log`: `.legion/tasks/axiom-autossh-c1-runtime-fix/log.md`
- `tasks`: `.legion/tasks/axiom-autossh-c1-runtime-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-autossh-c1-runtime-fix/docs/test-report.md`
- `change-review`: `.legion/tasks/axiom-autossh-c1-runtime-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-autossh-c1-runtime-fix/docs/report-walkthrough.md`
