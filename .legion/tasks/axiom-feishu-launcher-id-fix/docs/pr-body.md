## Summary

- Use Quickshell's actual Feishu app id, `bytedance-feishu`, for Axiom Caelestia launcher favourites.
- Migrate existing mutable Caelestia configs away from the legacy incorrect `bytedance-feishu.desktop` favourite.
- Keep Feishu package discovery through the upstream `share/applications/bytedance-feishu.desktop` file.

## Validation

- `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.settings.launcher.favouriteApps"`
- `nix eval --json --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); pkgs = flake.nixosConfigurations.axiom.config.user.packages; feishu = builtins.elemAt (builtins.filter (p: (p.pname or p.name or "") == "feishu") pkgs) 0; in builtins.pathExists (feishu + "/share/applications/bytedance-feishu.desktop")'`
- `printf '%s\n' '{"launcher":{"favouriteApps":["steam","bytedance-feishu.desktop"]}}' | jq --arg app "bytedance-feishu" --arg legacy "bytedance-feishu.desktop" '.launcher = (.launcher // {}) | .launcher.favouriteApps = ((.launcher.favouriteApps // []) as $apps | ($apps | map(select(. != $legacy))) as $normalized | if ($normalized | index($app)) then $normalized else $normalized + [$app] end)'`
- `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.preStart" --apply 'hooks: builtins.any (hook: builtins.match ".*axiom-ensure-feishu-launcher-favorite.*" hook != null) hooks'`
- `nix build --no-link --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.modules.desktop.caelestia.session.preStart 0' && script="$(nix eval --raw --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.modules.desktop.caelestia.session.preStart 0')" && bash -n "$script"`
- `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`
- `git diff --check`
