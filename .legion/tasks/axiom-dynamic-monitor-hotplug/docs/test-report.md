# Test Report

## Commands

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/monitors.conf".text'`
- `nix eval --json '.#nixosConfigurations.axiom.config.modules.desktop.hyprland.monitorHotplug'`
- `nix eval --json '.#nixosConfigurations.axiom.config.modules.desktop.hyprland.monitors'`
- `nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.activationPackage'`
- `nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.system.build.toplevel'`
- `bash -n /nix/store/vxin80w0hgc7xp211f6zz58mnghy6ycr-hyprland-reconcile-monitors/bin/hyprland-reconcile-monitors`
- `bash -n /nix/store/m4mg5vnpm1mywy39mkf3rxfyq1h6zxgv-hyprland-monitor-hotplug`
- Static jq sample using the generated monitor inventory for unknown 4K120 and known DP-4 cases.
- `git diff --check`

## Results

- Generated `hypr/monitors.conf` keeps explicit safe startup rules:
  - `monitor = DP-4,3840x2160@240,0x0,1.500000`
  - `monitor = DP-5,3840x2160@60,2560x0,1.500000`
- Monitor hotplug options evaluate with `enable = true` and unknown outputs using `modePolicy = native-max-refresh`, `position = auto`, `scale = 1.5`.
- Monitor inventory evaluates with identity hints for the Microstep OLED and Dell U2720QM.
- Caelestia pre-start integration currently evaluates to the existing Axiom global settings migration only, because Axiom has not declared concrete per-monitor Caelestia overrides. The implementation supports adding per-monitor overrides under the same monitor entries without a separate config surface.
- Home Manager activation and NixOS system toplevel both build without switching the system.
- Generated reconcile helper and event watcher pass `bash -n`.
- Static mode-selection sample outputs:
  - `HDMI-A-1,3840x2160@120.00,auto,1.5`
  - `DP-4,3840x2160@240.00,0x0,1.5`
- `git diff --check` passes.

## Why These Checks

These checks directly exercise the changed surfaces: Nix option evaluation proves the cohesive monitor inventory and generated static Hyprland rules, the Home Manager and NixOS builds realize both generated scripts and service units, `bash -n` catches shell syntax errors in the generated runtime code, and the jq sample proves the key policy decision for unknown 4K120 displays without mutating the live compositor session.

## Live Smoke After Deploy

- Run `hey sync --host axiom switch` from an interactive terminal.
- Restart Hyprland or log out/in so the user service and generated scripts are cleanly loaded.
- Confirm `systemctl --user status hyprland-monitor-hotplug.service` is active.
- Confirm `hyprctl monitors all -j` reports DP-4 at 4K240 and DP-5 at 4K60.
- Plug a 4K120 display and confirm it is configured at 4K120 with auto position and scale 1.5.

## Residual Risk

Hyprland/Aquamarine atomic commit failures can still leave a live session in an unrecoverable bad modeset state. The reconciler avoids unsafe static rules and handles normal hotplug, but a clean Hyprland restart remains the fallback after repeated atomic commit failures.
