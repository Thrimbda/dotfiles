# Axiom Feishu Launcher Discovery Fix

## Metadata

- `task-id`: `axiom-feishu-launcher-discovery-fix`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-feishu-launcher-entry`
- `superseded-by`: `axiom-feishu-launcher-id-fix`

## Outcome Summary

This task fixed the package desktop-entry data exposure path for Axiom Caelestia, but it was superseded for Feishu favourites by `axiom-feishu-launcher-id-fix`: Quickshell discovers `share/applications/bytedance-feishu.desktop` as desktop-entry id `bytedance-feishu`, not `bytedance-feishu.desktop`.

The XDG data exposure conclusion remains useful for app discovery, but the favourite id from this task is no longer current. Use `bytedance-feishu` for Caelestia favourites.

## Reusable Decisions

- Caelestia launcher favourites require the desktop id to be discoverable by Quickshell `DesktopEntries`; favourite config alone is insufficient if the service environment cannot see the package's desktop-entry data.
- For Axiom Caelestia launcher discovery regressions involving Nix-installed apps, check `caelestia-shell.service.environment.XDG_DATA_DIRS` before creating duplicate desktop entries.
- Keep app discovery fixes service-local when only Caelestia Shell needs the extra XDG data lookup surface.

## Validation Summary

- `XDG_DATA_DIRS` eval confirms the Caelestia shell service environment includes Feishu's package `share` path.
- A Nix `pathExists` eval confirms Feishu still ships `share/applications/bytedance-feishu.desktop`.
- Feishu package presence, launcher favourite config, existing pre-start favourite hook, Axiom toplevel eval, and `git diff --check` passed.
- Live `Super+Space` rendering remains a post-deploy Axiom Wayland smoke check.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-feishu-launcher-discovery-fix/plan.md`
- `rfc`: `.legion/tasks/axiom-feishu-launcher-discovery-fix/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-feishu-launcher-discovery-fix/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-feishu-launcher-discovery-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-feishu-launcher-discovery-fix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-feishu-launcher-discovery-fix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-feishu-launcher-discovery-fix/docs/pr-body.md`

## Notes

- After deployment on Axiom, restart `caelestia-shell.service` or start a new Hyprland session, open `Super+Space`, and confirm Feishu is visible and launches.
