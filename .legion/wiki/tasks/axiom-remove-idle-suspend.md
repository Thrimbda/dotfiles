# axiom-remove-idle-suspend

## Metadata

- `task-id`: `axiom-remove-idle-suspend`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `axiom-hyprland-xwayland-idle-crash-fix` idle-owner and timing conclusions only

## Outcome Summary

- This task's no-automatic-suspend conclusion remains current for Axiom.
- Its earlier Hypridle ownership, `hyprlock`, and 5/10-minute timing conclusions are superseded by `axiom-hyprland-xwayland-idle-crash-fix`: Caelestia owns the current 15-minute lock and 30-minute DPMS policy.
- This task does not remove manual suspend capability, Caelestia power controls, polkit allowlists, or existing Keep Awake/session-inhibitor wiring.
- Validation passed for focused suspend-string search, `git diff --check`, and the Axiom NixOS toplevel build.

## Reusable Decisions

- Neither Caelestia nor Hypridle should be treated as Axiom's automatic suspend owner unless a future task explicitly restores that behavior.
- For Axiom idle policy changes, distinguish idle lock/DPMS behavior from manual suspend permissions and Caelestia power-control authorization.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-remove-idle-suspend/plan.md`
- `log`: `.legion/tasks/axiom-remove-idle-suspend/log.md`
- `tasks`: `.legion/tasks/axiom-remove-idle-suspend/tasks.md`
- `test-report`: `.legion/tasks/axiom-remove-idle-suspend/docs/test-report.md`
- `review`: `.legion/tasks/axiom-remove-idle-suspend/docs/review-change.md`
- `report`: `.legion/tasks/axiom-remove-idle-suspend/docs/report-walkthrough.md`
