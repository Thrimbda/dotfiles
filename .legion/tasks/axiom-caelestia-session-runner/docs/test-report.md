# Test Report

Status: PASS

Validated in worktree: `.worktrees/axiom-caelestia-session-runner`

## Commands

- `nix build '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
- `control="$(nix eval --raw '.#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.controlCommand')" && test -x "$control" && bash -n "$control" && "$control" status`
- `nix eval '.#nixosConfigurations.axiom.config.systemd.user.services' --apply 'services: builtins.hasAttr "caelestia-shell" services'`
- `nix eval --json '.#nixosConfigurations.axiom.config.hey.hooks.startup'`
- `nix eval '.#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.xdgDataDirs' --apply 'dirs: builtins.match ".*feishu.*" dirs != null'`
- Assembled generated Hyprland config under `.legion/tasks/axiom-caelestia-session-runner/tmp/hypr-verify` and ran `Hyprland --verify-config --config <assembled>/hyprland.conf`; temp files were removed after the check.

## Results

- Axiom toplevel builds successfully.
- Generated `caelestia-session` script exists, passes `bash -n`, and its `status` command can query the running Quickshell instance.
- Evaluated `systemd.user.services` no longer contains `caelestia-shell`.
- Startup hook ordering is `05-session`, `06-caelestia-shell`, then `07-caelestia-keep-awake`.
- Feishu package share path remains exposed through `modules.desktop.caelestia.session.xdgDataDirs`.
- Hyprland config verification reports `config ok`.

## Remaining Live Checks

- Deploy/switch the new generation on Axiom.
- Start or restart Caelestia from inside the real Hyprland session.
- Confirm `/proc/<caelestia-pid>/cgroup` contains `session-*.scope`.
- Confirm Caelestia Wi-Fi and power/session controls no longer report authorization failures.
