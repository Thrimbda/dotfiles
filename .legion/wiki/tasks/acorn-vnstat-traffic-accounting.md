# acorn-vnstat-traffic-accounting

## Metadata

- `task-id`: `acorn-vnstat-traffic-accounting`
- `status`: `active`
- `risk`: `high`
- `schema-version`: `1`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Acorn now enables the native NixOS `vnstat` daemon for durable interface-level daily and monthly traffic totals.
- The service was built on Axiom and activated remotely on Acorn; it is active and has registered the primary `ens5` interface.
- This is the current baseline for detecting future billable egress spikes. It cannot reconstruct historic traffic or attribute traffic to RustDesk, FRP, Nginx, or individual processes.

## Reusable Decisions

- Keep Acorn traffic accounting local and non-network-facing; do not add firewall rules, public telemetry, or credentials for aggregate billing visibility.
- If aggregate data identifies a continued problem, create a separate task for process-level or cloud-flow attribution rather than expanding `vnstat` scope.

## Related Raw Sources

- `plan`: `.legion/tasks/acorn-vnstat-traffic-accounting/plan.md`
- `log`: `.legion/tasks/acorn-vnstat-traffic-accounting/log.md`
- `tasks`: `.legion/tasks/acorn-vnstat-traffic-accounting/tasks.md`
- `rfc`: `.legion/tasks/acorn-vnstat-traffic-accounting/docs/rfc.md`
- `reviews`: `.legion/tasks/acorn-vnstat-traffic-accounting/docs/review-rfc.md`, `.legion/tasks/acorn-vnstat-traffic-accounting/docs/review-change.md`
- `test report`: `.legion/tasks/acorn-vnstat-traffic-accounting/docs/test-report.md`
- `report`: `.legion/tasks/acorn-vnstat-traffic-accounting/docs/report-walkthrough.md`
