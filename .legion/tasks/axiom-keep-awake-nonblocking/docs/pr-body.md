## Summary

- Run the Axiom Keep Awake retry helper asynchronously from the startup hook so it no longer blocks shell startup while waiting for Caelestia IPC.
- Preserve the direct Caelestia `idleInhibitor` IPC command and the 120-attempt cold-start retry window.

## Validation

- Targeted `nix eval --impure --json --expr '...'` assertions passed for `nohup`, backgrounding, output suppression, startup hook ordering, direct IPC, 120 retries, and old wrapper absence.
- `git diff --check` passed.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

## Notes

- Post-deploy, start a fresh Hyprland session and confirm shell startup is no longer delayed while Keep Awake still reports enabled after Caelestia IPC is ready.
