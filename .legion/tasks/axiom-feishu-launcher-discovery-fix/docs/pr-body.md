## Summary

- Expose Axiom user/system package `share` paths to `caelestia-shell.service` via `XDG_DATA_DIRS` so Quickshell desktop-entry discovery can see Feishu.
- Preserve the existing `bytedance-feishu.desktop` favourite and mutable Caelestia `shell.json` updater.
- Add Legion RFC, verification, review, and walkthrough evidence for the launcher discovery fix.

## Validation

- `nix eval --json ".#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.environment.XDG_DATA_DIRS" --apply 'dirs: builtins.match ".*feishu-[^:]+/share(:|$).*" dirs != null'`
- `nix eval --json --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); pkgs = flake.nixosConfigurations.axiom.config.user.packages; feishu = builtins.elemAt (builtins.filter (p: (p.pname or p.name or "") == "feishu") pkgs) 0; in builtins.pathExists (feishu + "/share/applications/bytedance-feishu.desktop")'`
- `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.settings.launcher.favouriteApps"`
- `nix eval --json ".#nixosConfigurations.axiom.config.user.packages" --apply 'pkgs: builtins.filter (name: name == "feishu") (builtins.map (p: p.pname or p.name or "") pkgs)'`
- `nix eval --json ".#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre" --apply 'hooks: builtins.any (hook: builtins.match ".*axiom-ensure-feishu-launcher-favorite.*" hook != null) hooks'`
- `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`
- `git diff --check`

## Notes

- Live launcher rendering remains a post-deploy Axiom Wayland smoke check.
