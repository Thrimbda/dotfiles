# Log

## 2026-05-28

- User requested removing Axiom Hyprlock and using Caelestia WlSessionLock only.
- Confirmed the pinned Caelestia shell includes `modules/lock/Lock.qml` with `WlSessionLock` and an IPC target `lock` exposing `lock`, `unlock`, and `isLocked`.
- Switched generated `SUPER+SHIFT+L`, Hypridle lock commands, and `hey .lock` to `caelestia shell lock lock`.
- Removed Hyprlock package/PAM wiring and repository-owned Hyprlock config/helpers.
- Updated Axiom README and Legion wiki decisions/patterns/maintenance/log.
- Static and Nix validation passed; live graphical lock/unlock smoke remains a post-deploy check.

## Blocked / Pending

- No code blocker known.
- Live Axiom Hyprland session validation remains pending: run `caelestia shell lock lock`, unlock, then test `SUPER+SHIFT+L` and Hypridle-triggered lock.
