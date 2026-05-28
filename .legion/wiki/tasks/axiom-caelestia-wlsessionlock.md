# axiom-caelestia-wlsessionlock

## Metadata

- `task-id`: `axiom-caelestia-wlsessionlock`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom ordinary idle/keybind locks now use Caelestia's native WlSessionLock via `caelestia shell lock lock`.
- The Hyprland module no longer installs Hyprlock or declares `security.pam.services.hyprlock`.
- Repository-owned Hyprlock config and helper scripts were removed.
- `hey .lock` remains as a compatibility entrypoint but delegates to Caelestia lock IPC.
- Hypridle still owns the 15 minute lock timing and 30 minute DPMS timing, but its lock action now targets Caelestia.

## Reusable Decisions

- Treat Caelestia WlSessionLock as Axiom's current ordinary lock surface.
- Do not restore Hyprlock as a fallback unless a future scoped task explicitly requires a separate lock client.
- Keep `loginctl lock-session` separate from direct Caelestia lock IPC until the logind path is intentionally revalidated.
- Service-owned lock commands must have explicit PATH coverage for both `caelestia` and `caelestia-shell`.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-wlsessionlock/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-wlsessionlock/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-wlsessionlock/tasks.md`
- `test-report`: `.legion/tasks/axiom-caelestia-wlsessionlock/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-wlsessionlock/docs/review-change.md`
- `report`: `.legion/tasks/axiom-caelestia-wlsessionlock/docs/report-walkthrough.md`
