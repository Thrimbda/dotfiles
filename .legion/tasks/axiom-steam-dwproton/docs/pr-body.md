## Summary

- add the pinned `imaviso/dwproton-flake` input
- add opt-in `modules.desktop.apps.steam.dwproton.enable` wiring to `programs.steam.extraCompatPackages`
- enable DWProton only for Axiom's Steam config

## Verification

- `nix eval --json '.#nixosConfigurations.axiom.config.modules.desktop.apps.steam.dwproton.enable'` -> `true`
- `nix eval --json '.#nixosConfigurations.axiom.config.programs.steam.extraCompatPackages' --apply 'packages: map (package: package.name or package.pname or "unknown") packages'` -> `["dwproton-11.0-4"]`
- `nix eval --json '.#nixosConfigurations.azar.config.modules.desktop.apps.steam.dwproton.enable'` -> `false`
- `nix eval --json '.#nixosConfigurations.azar.config.programs.steam.extraCompatPackages' --apply 'packages: map (package: package.name or package.pname or "unknown") packages'` -> `[]`
- `nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-steam-dwproton"; in builtins.elemAt flake.nixosConfigurations.axiom.config.programs.steam.extraCompatPackages 0'`
- `nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.system.build.toplevel'`
- `git diff --check`

## Notes

- Live Steam UI selection remains a post-deploy smoke check after `hey sync --host axiom switch` and Steam restart.
