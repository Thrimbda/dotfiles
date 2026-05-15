# axiom-caelestia-steam-display-fix

## Metadata

- `task-id`: `axiom-caelestia-steam-display-fix`
- `status`: `completed`
- `risk`: `low-medium`
- `schema-version`: `2026-05-15`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Steam launched from the Axiom Caelestia launcher failed with `Unable to open a connection to X` because the Caelestia session runner and Quickshell process lacked `DISPLAY`, while the wider Hyprland/XWayland session was healthy.
- `caelestia-session` now hydrates missing display/session variables from the systemd user manager using a fixed allowlist before launching Caelestia Shell.
- The fix avoids hard-coding `DISPLAY=:0`, preserves existing PATH/Qt/Hyprland behavior, and imports only expected display/session variables.
- Live validation restarted Caelestia with the new generated script and confirmed `caelestia-session` plus `quickshell` now include `DISPLAY=:0`; a launcher-like Steam smoke launch no longer logged `XOpenDisplay failed`.

## Reusable Decisions

- Caelestia Shell is a launcher/app parent and must inherit both Wayland and XWayland display variables, not just Wayland/Hyprland variables.
- When a launcher-owned GUI app reports `XOpenDisplay failed`, validate the launcher parent process environment before changing the app package or Steam runtime.
- Use the systemd user manager as the display/session source of truth after Hyprland startup imports its environment, and import only a narrow allowlist into launcher-owned children.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-steam-display-fix/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-steam-display-fix/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-steam-display-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-caelestia-steam-display-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-steam-display-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-caelestia-steam-display-fix/docs/report-walkthrough.md`

## Notes

- A later Steam `Download failed: http error 0` was observed after the display failure was cleared; treat that as a separate Steam/network/runtime task if it becomes user-visible.
- The live Caelestia session was hot-restarted with the generated fixed script during validation, so the current session has the fix before a full NixOS switch.
