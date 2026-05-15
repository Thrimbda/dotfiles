## Summary

- Extend the Axiom Keep Awake startup helper retry window so it covers Caelestia session cold-start IPC registration.
- Preserve direct `caelestia-shell ipc call idleInhibitor enable` usage and keep Caelestia's Keep Awake UI as the source of truth.

## Validation

- Runtime diagnosis confirmed `caelestia-session start` returns before IPC registration; the observed shell instance registered about 11 seconds after session startup while the helper only retried for about 10 seconds.
- Manual helper smoke in the live graphical session returned `true` after enabling.
- Targeted `nix eval --impure --json --expr '...'` assertions passed for hook ordering, direct IPC usage, 120 retry attempts, and old wrapper absence.
- `git diff --check` passed.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

## Notes

- Post-deploy, start a fresh Hyprland session or restart `caelestia-session`, then confirm `caelestia shell idleInhibitor isEnabled` reports enabled after Caelestia finishes cold startup.
