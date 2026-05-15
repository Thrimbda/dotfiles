# Test Report

## Summary

PASS. Focused Nix checks confirm Axiom now declares `bytedance-feishu.desktop` as a Caelestia launcher favourite, keeps `feishu` installed, adds the existing-config updater to `caelestia-shell.service` pre-start hooks, and still evaluates the Axiom NixOS toplevel.

## Commands

1. `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.settings.launcher.favouriteApps"`
   - Result: PASS
   - Evidence: output is `["bytedance-feishu.desktop"]`.

2. `nix eval --json ".#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre"`
   - Result: PASS
   - Evidence: output includes `axiom-ensure-feishu-launcher-favorite` after the existing Caelestia seed scripts.

3. `nix eval --json ".#nixosConfigurations.axiom.config.user.packages" --apply 'pkgs: builtins.filter (name: name == "feishu") (builtins.map (p: p.pname or p.name or "") pkgs)'`
   - Result: PASS
   - Evidence: output is `["feishu"]`.

4. `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`
   - Result: PASS
   - Evidence: produced `/nix/store/p0dhaf1l8y0jy2g5zvz2x82ja8rl17lw-nixos-system-axiom-25.11.20260203.e576e3c.drv` after rebasing onto the latest `origin/master`.

5. `nix build --no-link --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre 2' && script="$(nix eval --raw --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre 2')" && bash -n "$script"`
   - Result: PASS
   - Evidence: Nix built the updater script derivation and `bash -n` accepted it.

6. `git diff --check`
   - Result: PASS
   - Evidence: no whitespace errors reported.

7. `git diff --check HEAD~1 HEAD`
   - Result: PASS
   - Evidence: no whitespace errors reported after the rebase conflict resolution.

## Why These Checks

- The favouriteApps eval directly proves the menu-visible Caelestia setting is declared for Axiom.
- The ExecStartPre eval and script syntax check prove existing mutable `shell.json` files get a conservative Feishu favourite append path after the normal seed step.
- The package eval ensures the previous package installation remains intact.
- The toplevel eval ensures the host configuration remains valid after the launcher integration.

## Notes

- Nix emitted pre-existing warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; none blocked evaluation.
- Some eval-cache SQLite busy warnings were ignored by Nix and did not affect the final results.

## Skipped

- Live `Super+Space` rendering and app launch were not tested in a real Axiom Wayland session. This environment can validate generated configuration and scripts, but not layer-shell UI behavior.
