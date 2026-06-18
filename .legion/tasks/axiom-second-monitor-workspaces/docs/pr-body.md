## Summary

- add Axiom-only secondary workspace support for workspaces 11-20 on DP-5
- add `SUPER+ALT+1..0` and `SUPER+ALT+SHIFT+1..0` generated Hyprland bindings for second-monitor workspace switching and window moves
- update generated shortcut help while preserving existing `SUPER+1..0` and `SUPER+SHIFT+1..0` primary workspace behavior

## Verification

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/workspaces.conf".text'`
- `nix eval --raw '.#nixosConfigurations.azar.config.home-manager.users.c1.home.file.".config/hypr/workspaces.conf".text'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/keybinds.conf".text'`
- `nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.activationPackage'`
- `git diff --check`

## Legion Evidence

- Task: `.legion/tasks/axiom-second-monitor-workspaces/plan.md`
- Test report: `.legion/tasks/axiom-second-monitor-workspaces/docs/test-report.md`
- Review: `.legion/tasks/axiom-second-monitor-workspaces/docs/review-change.md`
