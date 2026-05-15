# Axiom Feishu Launcher Entry

## Metadata

- `task-id`: `axiom-feishu-launcher-entry`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task makes Feishu visible in Axiom's `Super+Space` launcher menu. The implementation adds Feishu's upstream desktop id, `bytedance-feishu.desktop`, to Axiom's Caelestia `launcher.favouriteApps` setting.

Because Caelestia's `shell.json` is intentionally user-mutable, the task also adds an Axiom-only `caelestia-shell.service` pre-start updater that appends `bytedance-feishu.desktop` to an existing mutable config without replacing other settings.

The current effective conclusion is launcher integration only: Feishu remains package-installed, but account state, proxy, cache, autostart, credentials, and organization policy remain out of scope. Live `Super+Space` rendering and app launch remain post-deploy smoke checks.

## Reusable Decisions

- Current Axiom `Super+Space` opens the Caelestia launcher drawer; default-visible app additions should target Caelestia launcher configuration, not a raw package list.
- For Caelestia default-visible apps, use the upstream desktop entry id in `launcher.favouriteApps` and avoid duplicate desktop entries when the package already ships one.
- When an existing mutable Caelestia `shell.json` needs a narrow repository-owned addition, append only the missing value and preserve all other user settings.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-feishu-launcher-entry/plan.md`
- `log`: `.legion/tasks/axiom-feishu-launcher-entry/log.md`
- `tasks`: `.legion/tasks/axiom-feishu-launcher-entry/tasks.md`
- `test-report`: `.legion/tasks/axiom-feishu-launcher-entry/docs/test-report.md`
- `review`: `.legion/tasks/axiom-feishu-launcher-entry/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-feishu-launcher-entry/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-feishu-launcher-entry/docs/pr-body.md`

## Notes

- After this branch is applied to `axiom`, restart `caelestia-shell.service` or start a new Hyprland session, open `Super+Space`, and confirm Feishu is visible and launches.
