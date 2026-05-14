# Test Report

## Scope

Validate that Axiom's generated GTK, qtengine, and Fcitx theme state matches the approved RFC: GTK uses Breeze-Dark to align with Caelestia/qtengine BreezeDark, and Fcitx uses FluentDark through declarative module ownership.

## Commands

1. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.hey.info.theme.gtk`
   - Result: PASS.
   - Output includes `"theme":{"name":"Breeze-Dark"}`, `"iconTheme":{"name":"Papirus-Dark"}`, and `"cursorTheme":{"name":"Bibata-Modern-Classic","size":32}`.
   - Reason: verifies the user-facing theme metadata no longer reports `Graphite-pink-Dark`.

2. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.home-manager.users.c1.gtk.theme.name`
   - Result: PASS, output `"Breeze-Dark"`.
   - Reason: verifies Home Manager will generate the GTK theme name consumed by GTK apps such as Thunar.

3. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.home-manager.users.c1.gtk.theme.package.name`
   - Result: PASS, output `"breeze-gtk-6.5.5"`.
   - Reason: verifies the selected GTK theme package is KDE's Breeze GTK package.

4. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.programs.qtengine.config.theme.colorScheme`
   - Result: PASS, output points to `BreezeDark.colors` under the KDE Breeze package.
   - Reason: verifies the GTK change is aligned with the existing Caelestia/qtengine dark direction.

5. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection.Theme`
   - Result: PASS, output `"FluentDark"`.
   - Reason: verifies the NixOS Fcitx classic UI setting uses the new Axiom theme.

6. `nix eval --option eval-cache false --raw .#nixosConfigurations.axiom.config.home.configFile.'"fcitx5/conf/classicui.conf"'.text`
   - Result: PASS, output `Theme=FluentDark`.
   - Reason: verifies the Home Manager-owned Fcitx config file matches the NixOS setting.

7. `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.i18n.inputMethod.fcitx5.addons --apply 'addons: { hasFluent = builtins.any (pkg: builtins.match "fcitx5-fluent-.*" (pkg.name or "") != null) addons; hasCatppuccin = builtins.any (pkg: builtins.match "catppuccin-fcitx5.*" (pkg.name or "") != null) addons; names = map (pkg: pkg.name or "") addons; }'`
   - Result: PASS.
   - Output: `hasFluent = true`, `hasCatppuccin = false`, and addon names include `fcitx5-fluent-0.4.0-unstable-2024-03-30`.
   - Reason: verifies the Axiom Fcitx theme closure uses FluentDark's package and no longer pulls Catppuccin through the theme path.

8. `git diff --check`
   - Result: PASS.
   - Reason: checks whitespace and patch formatting.

9. `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`
   - Result: PASS.
   - Reason: verifies the Axiom NixOS toplevel remains evaluable/buildable with the GTK and Fcitx theme changes.

## Warnings

- Nix emitted an existing warning about `specialArgs.pkgs` causing `nixpkgs.config` and overlay options to be ignored.
- The toplevel dry-run emitted existing deprecation/rename warnings for `mesa.drivers`, `hardware.pulseaudio`, and `system`.
- These warnings are not introduced by this task and did not block evaluation.

## Skipped

- No live `nixos-rebuild switch` was run, per contract.
- No live Thunar or Fcitx visual smoke was run. After deployment, open Thunar and trigger Fcitx in the Axiom graphical session to confirm perceived contrast.
