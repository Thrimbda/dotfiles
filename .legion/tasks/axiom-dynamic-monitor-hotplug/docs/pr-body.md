## Summary

- extend the Hyprland monitor config into a cohesive inventory with identity matching, dynamic mode policy, fallback modes, and optional Caelestia per-monitor settings
- enable Axiom monitor hotplug reconciliation so known and unknown displays use native/highest-resolution first, then highest refresh at that resolution
- add a Hyprland event-socket watcher and startup/reload reconciliation hooks while keeping static DP-4/DP-5 startup rules safe and explicit

## Verification

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/monitors.conf".text'`
- `nix eval --json '.#nixosConfigurations.axiom.config.modules.desktop.hyprland.monitorHotplug'`
- `nix eval --json '.#nixosConfigurations.axiom.config.modules.desktop.hyprland.monitors'`
- `nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.activationPackage'`
- `nix build --no-link --print-out-paths '.#nixosConfigurations.axiom.config.system.build.toplevel'`
- `bash -n` on generated reconcile helper and hotplug watcher
- static jq sample for unknown 4K120 and known DP-4 mode selection
- `git diff --check`

## Legion Evidence

- Task: `.legion/tasks/axiom-dynamic-monitor-hotplug/plan.md`
- RFC: `.legion/tasks/axiom-dynamic-monitor-hotplug/docs/rfc.md`
- Test report: `.legion/tasks/axiom-dynamic-monitor-hotplug/docs/test-report.md`
- Review: `.legion/tasks/axiom-dynamic-monitor-hotplug/docs/review-change.md`
