# axiom-remove-default-keep-awake

## Metadata

- `task-id`: `axiom-remove-default-keep-awake`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-keep-awake-nonblocking`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom no longer enables Caelestia Keep Awake / `idleInhibitor` by default during Hyprland/Caelestia session startup.
- Caelestia Keep Awake remains available as a manual UI / IPC toggle for temporary no-idle behavior.
- The current default idle behavior is the aligned 15 minute lock and 30 minute DPMS policy, with no automatic idle sleep.
- If a prior session persisted Keep Awake enabled, the user may need to toggle it off once; Axiom no longer forces it back on at startup.

## Reusable Decisions

- Do not validate Axiom idle policy by checking Hypridle only; also check Caelestia `general.idle.timeouts` and absence of default `idleInhibitor enable` wiring.
- Treat Keep Awake as manual unless a future scoped task explicitly restores default never-sleep or default no-idle behavior.
- Preserve manual Caelestia Keep Awake commands while removing default startup enablement.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-remove-default-keep-awake/plan.md`
- `log`: `.legion/tasks/axiom-remove-default-keep-awake/log.md`
- `tasks`: `.legion/tasks/axiom-remove-default-keep-awake/tasks.md`
- `test-report`: `.legion/tasks/axiom-remove-default-keep-awake/docs/test-report.md`
- `review`: `.legion/tasks/axiom-remove-default-keep-awake/docs/review-change.md`
- `report`: `.legion/tasks/axiom-remove-default-keep-awake/docs/report-walkthrough.md`
