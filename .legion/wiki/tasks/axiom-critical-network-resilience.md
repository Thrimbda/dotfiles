# axiom-critical-network-resilience

## Metadata

- `task-id`: `axiom-critical-network-resilience`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Hardened `axiom`'s critical network path against OOM and active-but-broken service states.
- Current effective design is tiered: system services (`sshd`, autossh, cloudflared, Clash service-mode/core) get strong OOM/resource protection; Clash GUI gets moderate user-unit protection and restart behavior.
- Healthchecks are non-destructive: cloudflared uses `/ready`, autossh compares the remote reverse endpoint host key against `axiom`'s local SSH host key, and Clash checks service/core/TUN state.
- Autossh healthchecks do not kill remote processes; stale remote `127.0.0.1:2223` listeners remain a manual cleanup case.
- The task also pins the autossh remote host key in `/etc/ssh/ssh_known_hosts`, makes cloudflared metrics explicit at `127.0.0.1:20241`, and enables capped zram swap.

## Reusable Decisions

- Use `OOMScoreAdjust` for kernel global OOM priority and `MemoryMin`/`MemoryLow` as cgroup reinforcement; do not rely on one layer alone for critical network survivability.
- Treat active-but-broken remote access as a health problem, not just a systemd state problem.
- Prefer host-key identity checks over generic SSH banners when proving a reverse SSH endpoint reaches the intended host.
- Do not let timer-driven healthchecks perform irreversible remote cleanup unless a separate design proves parser safety, authorization, rollback, and observability.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-critical-network-resilience/plan.md`
- `log`: `.legion/tasks/axiom-critical-network-resilience/log.md`
- `tasks`: `.legion/tasks/axiom-critical-network-resilience/tasks.md`
- `rfc`: `.legion/tasks/axiom-critical-network-resilience/docs/rfc.md`
- `research`: `.legion/tasks/axiom-critical-network-resilience/docs/research.md`
- `rfc review`: `.legion/tasks/axiom-critical-network-resilience/docs/review-rfc.md`
- `test report`: `.legion/tasks/axiom-critical-network-resilience/docs/test-report.md`
- `change review`: `.legion/tasks/axiom-critical-network-resilience/docs/review-change.md`
- `report`: `.legion/tasks/axiom-critical-network-resilience/docs/report-walkthrough.md`

## Notes

- No live `nixos-rebuild switch` was run during this task.
- Live OOM stress testing was intentionally skipped.
- After deployment, run healthcheck services/timers under systemd and inspect journals before relying on automatic recovery behavior.
