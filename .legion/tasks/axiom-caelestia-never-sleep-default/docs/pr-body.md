## Summary

- Add `axiom-caelestia-never-sleep.service` to block login1 sleep while Axiom's Hyprland/Caelestia session is active.
- Keep Caelestia's `idleInhibitor` enabled by default as the visible Keep Awake UI state.
- Update Axiom docs with live checks and the current-session stop command.

## Validation

- `git diff --check`
- Targeted `nix eval --impure --json --expr '...'` assertions for the session service and Keep Awake hook
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- Post-build `nix eval --impure --json --expr '...'` assertions for generated script contents

## Notes

- Manual suspend is intentionally blocked by default while the graphical session inhibitor is active.
- Post-deploy smoke on Axiom should check `caelestia shell idleInhibitor isEnabled`, `systemctl --user status axiom-caelestia-never-sleep.service`, and `systemd-inhibit --list | grep -i 'Axiom Caelestia'`.
