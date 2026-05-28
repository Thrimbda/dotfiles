## Summary

- Route Axiom idle/keybind lock requests through Caelestia WlSessionLock via `caelestia shell lock lock`.
- Remove active Hyprlock package, PAM, config, helper scripts, and stale flake comments.
- Update Axiom README plus Legion wiki current truth and follow-up smoke checks.

## Verification

- `zsh -n config/hypr/bin/lock.zsh config/hypr/hooks/idle.zsh`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/keybinds.conf".text'`
- `nix eval --json '.#nixosConfigurations.axiom.config.systemd.user.services.hypridle.path'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.system.build.toplevel.drvPath'`
- `nix build '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
- Axiom closure check for absence of `hyprlock`
- Hyprlock PAM absence eval returned `false`
- Active reference search for `hyprlock` under `flake.nix`, `modules`, `config`, and `hosts`
- `git diff --check`

## Residual Risk

- Live lock/unlock smoke still needs to run in the actual Axiom Hyprland/Caelestia session.
