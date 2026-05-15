## Summary

- Add Feishu's desktop id, `bytedance-feishu.desktop`, to Axiom's Caelestia launcher favourites so it appears in the `Super+Space` menu.
- Add an Axiom-only pre-start updater that appends the same favourite to an existing mutable Caelestia `shell.json` without overwriting other user settings.
- Keep Feishu package installation intact and avoid account/proxy/autostart/runtime state changes.

## Verification

- `nix eval --json ".#nixosConfigurations.axiom.config.modules.desktop.caelestia.settings.launcher.favouriteApps"`
- `nix eval --json ".#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre"`
- `nix eval --json ".#nixosConfigurations.axiom.config.user.packages" --apply 'pkgs: builtins.filter (name: name == "feishu") (builtins.map (p: p.pname or p.name or "") pkgs)'`
- `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`
- `nix build --no-link --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre 2' && script="$(nix eval --raw --impure --expr 'let flake = builtins.getFlake ("path:" + toString ./.); in builtins.elemAt flake.nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre 2')" && bash -n "$script"`
- `git diff --check`

## Evidence

- Test report: `.legion/tasks/axiom-feishu-launcher-entry/docs/test-report.md`
- Review: `.legion/tasks/axiom-feishu-launcher-entry/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-feishu-launcher-entry/docs/report-walkthrough.md`
