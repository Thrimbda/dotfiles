# axiom-hyprland-xwayland-idle-crash-fix

## Metadata

- `task-id`: `axiom-hyprland-xwayland-idle-crash-fix`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-caelestia-idle-timeouts` idle-owner conclusion only
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom keeps its 15 minute automatic lock and 30 minute DPMS policy, but Caelestia is now the only automatic idle owner.
- The Axiom Hypridle user unit is disabled without changing the default for other hosts; Caelestia retains WlSessionLock, RustDesk, and XWayland remain enabled, and no automatic idle suspend is introduced.
- The monitor hotplug watcher now discovers the active Hyprland socket on each reconnect and backs off when the compositor socket is absent or its event stream ends.
- Focused Nix/static checks pass. A real long-idle DPMS/wake test remains required after deployment, and the upstream XWayland/DRM crash remains an explicit residual rather than a claimed local root-cause fix.

## Reusable Decisions

- Do not run Hypridle and Caelestia as simultaneous Axiom 900/1800-second idle owners without a scoped compatibility investigation.
- A session-long `HYPRLAND_INSTANCE_SIGNATURE` is unsafe for a reconnecting event watcher; derive the socket from `hyprctl instances -j` and verify it is a socket before connecting.
- Do not use a Hyprland version-only upgrade as incident remediation unless the implicated upstream code or release notes demonstrate a relevant fix.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/plan.md`
- `log`: `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/log.md`
- `tasks`: `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/tasks.md`
- `rfc`: `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/docs/review-rfc.md`, `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/docs/report-walkthrough.md`
