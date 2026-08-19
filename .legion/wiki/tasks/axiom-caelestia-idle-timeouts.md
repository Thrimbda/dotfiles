# axiom-caelestia-idle-timeouts

## Metadata

- `task-id`: `axiom-caelestia-idle-timeouts`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `axiom-hyprland-xwayland-idle-crash-fix` idle-owner conclusion only

## Outcome Summary

- Axiom's Caelestia shell idle policy is aligned with Hypridle: 900 seconds to lock and 1800 seconds to DPMS off/on.
- Caelestia's upstream 600 second `systemctl suspend-then-hibernate` idle action is not part of the Axiom-owned settings.
- Existing mutable `~/.config/caelestia/shell.json` files are migrated at session startup so deployed sessions do not keep the upstream 180/300/600 second defaults.
- The earlier dual-owner alignment conclusion is superseded for Axiom by `axiom-hyprland-xwayland-idle-crash-fix`: Caelestia is Axiom's sole automatic idle owner, while Hypridle defaults remain available for other hosts.

## Reusable Decisions

- With Caelestia as Axiom's sole idle owner, validate its `general.idle.timeouts` and the absence of the Axiom Hypridle unit; do not treat the checked-in Hypridle config as active Axiom policy.
- For persisted Caelestia `shell.json`, changing only seed settings is insufficient. A narrow migration should update Axiom-owned fields while preserving unrelated user settings.
- Do not restore automatic idle sleep in either Hypridle or Caelestia without a new scoped task.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-idle-timeouts/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-idle-timeouts/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-idle-timeouts/tasks.md`
- `test-report`: `.legion/tasks/axiom-caelestia-idle-timeouts/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-idle-timeouts/docs/review-change.md`
- `report`: `.legion/tasks/axiom-caelestia-idle-timeouts/docs/report-walkthrough.md`
