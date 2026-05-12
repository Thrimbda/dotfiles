## Summary
- Refactors platform/env and desktop env constants while preserving the existing hlissner-style flake/module/host architecture.
- Adds an internal `_env.nix` helper for shared Hyprland/Caelestia Wayland/QT constants and reuses `mkEnvVars` for platform-specific env targets.
- Normalizes equivalent host-local home paths through `config.user.home` without changing ports, tunnel IDs, secret paths, service names, or desktop product choices.

## Validation
- `git diff --check`
- `nix eval .#hostMetadata --json`
- Targeted Axiom Hyprland/UWSM/Caelestia env evals
- Targeted Axiom/Azar/Charlie/Charles path/service evals
- `_env.nix` non-import eval check
- `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`

## Notes
- PR should not be auto-merged per user request.
- Live Axiom graphical-session and Darwin launchd smoke checks remain deployment-side.
