# acorn-traffic-attribution

## Metadata

- `task-id`: `acorn-traffic-attribution`
- `status`: `active`
- `risk`: `high`
- `schema-version`: `1`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Acorn now saves root-owned five-minute snapshots of selected systemd cgroup traffic totals and FRP TCP proxy totals for 30 days.
- `acorn-traffic-report` compares the newest two samples locally and separates service counters from named FRP proxy counters.
- Current evidence identifies `sshd` as the main service-level carrier of the August egress usage. This task intentionally does not retain remote-peer identity or packet/request content.

## Reusable Decisions

- Use `vnstat` for interface totals and the local attribution sampler for service/proxy evidence; do not add their counters together.
- Treat service restart and FRP daily-counter reset as an explicit report boundary, not as zero or negative traffic.
- Keep peer-level SSH attribution in a separate security/privacy-scoped task.

## Related Raw Sources

- `plan`: `.legion/tasks/acorn-traffic-attribution/plan.md`
- `log`: `.legion/tasks/acorn-traffic-attribution/log.md`
- `tasks`: `.legion/tasks/acorn-traffic-attribution/tasks.md`
- `rfc`: `.legion/tasks/acorn-traffic-attribution/docs/rfc.md`
- `reviews`: `.legion/tasks/acorn-traffic-attribution/docs/review-rfc.md`, `.legion/tasks/acorn-traffic-attribution/docs/review-change.md`
- `test report`: `.legion/tasks/acorn-traffic-attribution/docs/test-report.md`
- `report`: `.legion/tasks/acorn-traffic-attribution/docs/report-walkthrough.md`
