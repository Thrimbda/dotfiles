## Summary

- Replace the custom Axiom `axiom-sleep-mode` no-sleep layer with Caelestia's built-in Keep Awake / `idleInhibitor` capability.
- Add an Axiom user service that enables `caelestia shell idleInhibitor enable` when the Hyprland/Caelestia session starts.
- Remove the separate Power Mode launchers, Axiom Hypridle override, and custom sleep-inhibitor services so Caelestia's Keep Awake UI is the source of truth.

## Validation

- Targeted `nix eval --impure --json --expr '...'` assertions passed.
- Host-level stale wrapper grep under `hosts/axiom` passed.
- `git diff --check` passed.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

## Notes

- Live verification still needs the real Axiom graphical session: confirm Keep Awake is enabled after login and that the UI toggle controls the same state.
- This is graphical-session scoped and intentionally not a headless/system-wide sleep policy.
