# Test Report

## Summary

PASS. Focused validation confirms Axiom's `caelestia-shell.service` now receives an `XDG_DATA_DIRS` value that includes Feishu's package `share` directory, while the previous Feishu package and launcher favourite configuration remain intact. The Axiom toplevel still evaluates.

## Commands

1. `nix eval --json ".#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.environment.XDG_DATA_DIRS" --apply 'dirs: builtins.match ".*feishu-[^:]+/share(:|$).*" dirs != null'`
   - Result: PASS
   - Evidence: output is `true`.

2. `nix eval --json --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); pkgs = flake.nixosConfigurations.axiom.config.user.packages; feishu = builtins.elemAt (builtins.filter (p: (p.pname or p.name or "") == "feishu") pkgs) 0; in builtins.pathExists (feishu + "/share/applications/bytedance-feishu.desktop")'`
   - Result: PASS
   - Evidence: output is `true`.

3. `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.settings.launcher.favouriteApps"`
   - Result: PASS
   - Evidence: output is `["bytedance-feishu.desktop"]`.

4. `nix eval --json ".#nixosConfigurations.axiom.config.user.packages" --apply 'pkgs: builtins.filter (name: name == "feishu") (builtins.map (p: p.pname or p.name or "") pkgs)'`
   - Result: PASS
   - Evidence: output is `["feishu"]`.

5. `nix eval --json ".#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre" --apply 'hooks: builtins.any (hook: builtins.match ".*axiom-ensure-feishu-launcher-favorite.*" hook != null) hooks'`
   - Result: PASS
   - Evidence: output is `true`.

6. `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`
   - Result: PASS
   - Evidence: produced `/nix/store/f6qlfkdkqb5n992ir92krijjwg4wyp9r-nixos-system-axiom-25.11.20260203.e576e3c.drv`.

7. `git diff --check`
   - Result: PASS
   - Evidence: no whitespace errors reported.

## Why These Checks

- The `XDG_DATA_DIRS` eval directly proves the Caelestia shell process will have Feishu's package `share` path in the same environment Quickshell uses for desktop-entry discovery.
- The desktop-entry existence eval proves the Feishu package still ships `share/applications/bytedance-feishu.desktop` at that exposed path.
- The favourite, package, and pre-start-hook evals prove the previous launcher integration remains present.
- The toplevel eval proves the host configuration remains evaluable after the service environment change.

## Notes

- Nix emitted pre-existing warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; none blocked evaluation.
- Some eval-cache SQLite busy warnings were ignored by Nix and did not affect the final results.

## Skipped

- Live `Super+Space` rendering and app launch were not tested in a real Axiom Wayland session. This environment can validate generated configuration and desktop-entry discoverability inputs, but not layer-shell UI behavior.
