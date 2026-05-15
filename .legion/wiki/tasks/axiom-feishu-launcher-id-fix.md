# Axiom Feishu Launcher ID Fix

## Metadata

- `task-id`: `axiom-feishu-launcher-id-fix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-feishu-launcher-discovery-fix`
- `superseded-by`: `(none)`

## Outcome Summary

This task corrects the Feishu Caelestia launcher favourite from the desktop filename `bytedance-feishu.desktop` to Quickshell's actual desktop-entry id, `bytedance-feishu`. Quickshell scans the upstream desktop file but indexes it by complete basename, so Caelestia favourites must use the basename without `.desktop`.

The mutable config migration now removes the legacy incorrect Feishu favourite and appends `bytedance-feishu` while preserving unrelated favourites.

## Reusable Decisions

- Caelestia launcher favourites must use Quickshell `DesktopEntry.id`, not necessarily the literal `.desktop` filename.
- For package desktop files at `share/applications/<name>.desktop`, Quickshell's scanner derives the top-level app id as `<name>`.
- When correcting a previously seeded favourite id, migrate the known bad value narrowly and preserve unrelated user favourites.

## Validation Summary

- Favourite eval returns `["bytedance-feishu"]`.
- Feishu package still provides `share/applications/bytedance-feishu.desktop`.
- JQ migration test converts `["steam","bytedance-feishu.desktop"]` to `["steam","bytedance-feishu"]`.
- Session pre-start hook, migration script syntax, Axiom toplevel, and `git diff --check` passed.
- Live `shell.json` was manually updated to include `bytedance-feishu`, and `caelestia-session` was restarted for immediate UI retest.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-feishu-launcher-id-fix/plan.md`
- `test-report`: `.legion/tasks/axiom-feishu-launcher-id-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-feishu-launcher-id-fix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-feishu-launcher-id-fix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-feishu-launcher-id-fix/docs/pr-body.md`

## Notes

- Ask the user to re-open `Super+Space` after the live restart and confirm Feishu is visible.
