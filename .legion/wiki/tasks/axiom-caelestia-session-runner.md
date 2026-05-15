# Axiom Caelestia Session Runner

Status: implemented; live deployment validation pending

Task: `.legion/tasks/axiom-caelestia-session-runner/`

Branch: `legion/axiom-caelestia-session-runner-polkit`

## Summary

Axiom's Caelestia Shell lifecycle now uses a generated `caelestia-session` runner launched from the Hyprland startup hook instead of `caelestia-shell.service`. This keeps the shell process in the graphical login session so the existing `subject.local == true` polkit rule can authorize Caelestia-owned NetworkManager and logind controls without widening privileges.

## Key Changes

- `modules.desktop.caelestia.session.controlCommand` exposes the generated `caelestia-session` command.
- `06-caelestia-shell` startup hook launches the runner after `05-session` imports compositor environment.
- Axiom's Keep Awake hook now runs after the session runner.
- Feishu launcher migration, `XDG_DATA_DIRS`, opencode PATH, wallpaper seed, shell config seed, and Qt environment moved into the session-owned lifecycle.
- Shell stop/restart keybinds now call `caelestia-session stop|restart`.

## Validation

- Axiom toplevel build passed.
- Generated control script passed `bash -n` and status smoke.
- Evaluated Axiom no longer has `caelestia-shell` in `systemd.user.services`.
- Hook ordering and Feishu `XDG_DATA_DIRS` evals passed.
- Assembled Hyprland config verified with `config ok`.

## Follow-Up

Live deployment must confirm the Caelestia process cgroup is under `session-*.scope` and that Wi-Fi controls no longer fail authorization.
