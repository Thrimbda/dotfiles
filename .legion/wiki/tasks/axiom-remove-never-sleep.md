# axiom-remove-never-sleep

## Metadata

- `task-id`: `axiom-remove-never-sleep`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-caelestia-never-sleep-default`
- `superseded-by`: `axiom-remove-default-keep-awake`

## Outcome Summary

- Axiom no longer declares the generated `axiom-caelestia-never-sleep` script or `axiom-caelestia-never-sleep.service` user service.
- This historical summary previously preserved default Caelestia `idleInhibitor` enablement; current behavior after `axiom-remove-default-keep-awake` leaves Keep Awake as a manual toggle instead.
- The checked-in Hypridle policy now locks after 15 minutes and turns DPMS off after 30 minutes, with no automatic suspend listener.
- Active README and wiki guidance no longer instruct users to check or stop the removed service.

## Reusable Decisions

- Treat Hypridle as Axiom's current repository-owned idle lock and DPMS surface.
- Do not restore a repository-owned sleep-inhibitor service unless a future task explicitly reopens default never-sleep behavior.
- Historical task evidence for the removed service can remain for auditability, but current-truth docs should not present it as active behavior.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-remove-never-sleep/plan.md`
- `log`: `.legion/tasks/axiom-remove-never-sleep/log.md`
- `tasks`: `.legion/tasks/axiom-remove-never-sleep/tasks.md`
- `test-report`: `.legion/tasks/axiom-remove-never-sleep/docs/test-report.md`
- `review`: `.legion/tasks/axiom-remove-never-sleep/docs/review-change.md`
- `report`: `.legion/tasks/axiom-remove-never-sleep/docs/report-walkthrough.md`
