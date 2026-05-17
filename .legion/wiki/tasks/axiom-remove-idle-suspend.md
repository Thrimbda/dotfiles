# axiom-remove-idle-suspend

## Metadata

- `task-id`: `axiom-remove-idle-suspend`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's checked-in Hypridle policy no longer triggers automatic suspend after 15 minutes of idle time.
- The active checked-in idle behavior remains 5 minute lock through `hyprlock` and 10 minute DPMS off/on through `hyprctl`.
- This task does not remove manual suspend capability, Caelestia power controls, polkit allowlists, or existing Keep Awake/session-inhibitor wiring.
- Validation passed for focused suspend-string search, `git diff --check`, and the Axiom NixOS toplevel build.

## Reusable Decisions

- Hypridle should not be treated as Axiom's automatic suspend owner unless a future task explicitly restores that behavior.
- For Axiom idle policy changes, distinguish idle lock/DPMS behavior from manual suspend permissions and Caelestia power-control authorization.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-remove-idle-suspend/plan.md`
- `log`: `.legion/tasks/axiom-remove-idle-suspend/log.md`
- `tasks`: `.legion/tasks/axiom-remove-idle-suspend/tasks.md`
- `test-report`: `.legion/tasks/axiom-remove-idle-suspend/docs/test-report.md`
- `review`: `.legion/tasks/axiom-remove-idle-suspend/docs/review-change.md`
- `report`: `.legion/tasks/axiom-remove-idle-suspend/docs/report-walkthrough.md`
