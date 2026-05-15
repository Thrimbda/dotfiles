## Summary

- Fix Axiom's default Keep Awake startup helper so it calls the evaluated `caelestia-shell` binary directly instead of relying on `PATH` inside the oneshot service.
- Preserve Caelestia Keep Awake / `idleInhibitor` as the visible source of truth and keep the behavior graphical-session scoped.

## Validation

- Runtime diagnosis confirmed the deployed oneshot failed with `FileNotFoundError: 'caelestia-shell'` while `caelestia-shell.service` and `hyprland-session.target` were active.
- Manual direct IPC against the running shell returned `true` for `idleInhibitor isEnabled` after enabling.
- Targeted `nix eval --impure --json --expr '...'` assertions passed.
- `git diff --check` passed.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

## Notes

- Post-deploy, reset/restart `axiom-caelestia-keep-awake.service` or start a new Hyprland session, then confirm `caelestia shell idleInhibitor isEnabled` reports enabled.
