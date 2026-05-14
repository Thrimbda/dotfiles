## Summary

- Switch Autumnal GTK theming from `Graphite-pink-Dark` to KDE `Breeze-Dark` so Thunar aligns with the active Caelestia/qtengine BreezeDark direction.
- Generalize Fcitx theme selection to package/name options while preserving existing Catppuccin defaults.
- Set Axiom Fcitx to `FluentDark` via `pkgs.fcitx5-fluent`.

## Verification

- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.hey.info.theme.gtk`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.home-manager.users.c1.gtk.theme.name`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.home-manager.users.c1.gtk.theme.package.name`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.programs.qtengine.config.theme.colorScheme`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection.Theme`
- `nix eval --option eval-cache false --raw .#nixosConfigurations.axiom.config.home.configFile.'"fcitx5/conf/classicui.conf"'.text`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.i18n.inputMethod.fcitx5.addons --apply 'addons: { hasFluent = builtins.any (pkg: builtins.match "fcitx5-fluent-.*" (pkg.name or "") != null) addons; hasCatppuccin = builtins.any (pkg: builtins.match "catppuccin-fcitx5.*" (pkg.name or "") != null) addons; names = map (pkg: pkg.name or "") addons; }'`
- `git diff --check`
- `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`

## Notes

- No live `nixos-rebuild switch` was run.
- After deployment, open Thunar and trigger Fcitx in the Axiom graphical session to confirm final perceived contrast.
