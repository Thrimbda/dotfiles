## Summary

- Configure Axiom's Hyprland monitor mode as `3840x2160@240` instead of `3840x2160@60`.
- Add optional Hyprland monitor fields for future HDR/color-management config: `bitdepth`, `cm`, `sdrbrightness`, and `sdrsaturation`.
- Keep Axiom HDR disabled for now by preserving `render.cm_enabled = false`; 240Hz is the priority and HDR still needs real-session color-management validation.

## Validation

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/monitors.conf".text'`
- `git diff --check`
- `nix eval --raw ".#nixosConfigurations.azar.config.home-manager.users.c1.home.file.\".config/hypr/monitors.conf\".text"`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); lib = flake.inputs.nixpkgs.lib; cfg = (flake.nixosConfigurations.axiom.extendModules { modules = [ { modules.desktop.hyprland.monitors = lib.mkForce [ { output = "DP-1"; mode = "3840x2160@240"; position = "0x0"; scale = 1.5; bitdepth = 10; cm = "hdr"; sdrbrightness = 1.2; sdrsaturation = 0.98; } ]; } ]; }).config; in cfg.home-manager.users.c1.home.file.".config/hypr/monitors.conf".text'`

## Notes

- Real 240Hz output still needs confirmation on the physical Axiom Hyprland session with `hyprctl monitors` after applying the config.
- HDR remains a follow-up because it requires Hyprland color management, which is currently disabled to avoid the existing DPMS/resume crash workaround.
