# Test Report

## Summary

PASS. Focused checks confirm Axiom now declares `bytedance-feishu` as the Caelestia launcher favourite, the Feishu package still provides `share/applications/bytedance-feishu.desktop`, and the mutable-config migration normalizes the old `bytedance-feishu.desktop` favourite to the Quickshell id.

## Commands

1. `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.settings.launcher.favouriteApps"`
   - Result: PASS
   - Evidence: output is `["bytedance-feishu"]`.

2. `nix eval --json --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); pkgs = flake.nixosConfigurations.axiom.config.user.packages; feishu = builtins.elemAt (builtins.filter (p: (p.pname or p.name or "") == "feishu") pkgs) 0; in builtins.pathExists (feishu + "/share/applications/bytedance-feishu.desktop")'`
   - Result: PASS
   - Evidence: output is `true`.

3. `printf '%s\n' '{"launcher":{"favouriteApps":["steam","bytedance-feishu.desktop"]}}' | jq --arg app "bytedance-feishu" --arg legacy "bytedance-feishu.desktop" '.launcher = (.launcher // {}) | .launcher.favouriteApps = ((.launcher.favouriteApps // []) as $apps | ($apps | map(select(. != $legacy))) as $normalized | if ($normalized | index($app)) then $normalized else $normalized + [$app] end)'`
   - Result: PASS
   - Evidence: output keeps `steam`, removes `bytedance-feishu.desktop`, and appends `bytedance-feishu`.

4. `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.preStart" --apply 'hooks: builtins.any (hook: builtins.match ".*axiom-ensure-feishu-launcher-favorite.*" hook != null) hooks'`
   - Result: PASS
   - Evidence: output is `true`.

5. `nix build --no-link --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.modules.desktop.caelestia.session.preStart 0' && script="$(nix eval --raw --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.modules.desktop.caelestia.session.preStart 0')" && bash -n "$script"`
   - Result: PASS
   - Evidence: Nix built the migration script and `bash -n` accepted it.

6. `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`
   - Result: PASS
   - Evidence: produced `/nix/store/b5h37s58dipsyz41nfn5m5r67wajb9r2-nixos-system-axiom-25.11.20260203.e576e3c.drv` after rebasing onto latest `origin/master`.

7. `git diff --check`
   - Result: PASS
   - Evidence: no whitespace errors reported.

## Live Diagnostic Evidence

- Live `~/.config/caelestia/shell.json` had `bytedance-feishu.desktop` before this fix.
- Live `quickshell` already had `XDG_DATA_DIRS` containing Feishu's package `share` path, so discovery data exposure was no longer the active blocker.
- After manually adding `bytedance-feishu` to live `shell.json` and restarting `caelestia-session`, the new live `quickshell` process still has Feishu in `XDG_DATA_DIRS`.

## Notes

- Nix emitted pre-existing warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; none blocked evaluation.
- Some eval-cache SQLite busy warnings were ignored by Nix and did not affect final results.

## Skipped

- Visual confirmation in the `Super+Space` launcher still requires the user to check the live UI.
