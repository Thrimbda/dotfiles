# Test Report: Hlissner-aligned Architecture Cleanup

> **Date**: 2026-05-12
> **Worktree**: `.worktrees/hlissner-architecture-cleanup`
> **Branch**: `legion/hlissner-architecture-cleanup-clean-boundaries`

## Summary
- **Result**: PASS
- **Scope validated**: flake host discovery, Axiom NixOS eval/dry-build, Axiom generated Hyprland/UWSM/Caelestia env, Axiom/Azar/Charlie/Charles normalized user-home paths, helper file non-import behavior, and diff whitespace.
- **Known warnings**: Nix emitted existing warnings about `specialArgs.pkgs`, `mesa.drivers`, `hardware.pulseaudio` rename, and `system` rename. These are pre-existing evaluation warnings unrelated to this cleanup.
- **Skipped**: live Axiom Hyprland/Caelestia and real Darwin runtime smoke; those require target graphical/macOS sessions.

## Commands

### `git diff --check`
- **Why**: Catches whitespace errors after generated docs and Nix edits.
- **Result**: PASS.

### `git add -N .legion/tasks/hlissner-architecture-cleanup modules/desktop/_env.nix`
- **Why**: Git-backed flakes can ignore untracked new files; intent-to-add makes validation see new helper/docs without staging final content yet.
- **Result**: PASS.

### `nix eval .#hostMetadata --json`
- **Why**: Proves flake host discovery and NixOS/Darwin host metadata evaluation still work after task docs/helper files were added.
- **Result**: PASS.
- **Observed**: Hosts include `axiom`, `azar`, `charlie`, `charles`, and existing NixOS/Darwin host metadata.

### `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/env.conf".text'`
- **Why**: Verifies Hyprland generated env config still includes the expected functional env lines after constants moved to `modules/desktop/_env.nix`.
- **Result**: PASS.
- **Observed functional lines**: `XDG_CURRENT_DESKTOP=Hyprland`, `NIXOS_OZONE_WL=1`, `MOZ_ENABLE_WAYLAND=1`, `GTK_USE_PORTAL=1`, `QT_QPA_PLATFORM=wayland;xcb`, `QT_QPA_PLATFORMTHEME=qtengine`, terminal/browser/editor values.

### `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home.configFile."uwsm/env".text'`
- **Why**: Verifies generated UWSM env remains populated with PATH and Wayland/QT session values.
- **Result**: PASS.
- **Observed**: PATH includes `/home/c1/.local/bin`, `/home/c1/.opencode/bin`, per-user/system profiles, wrappers and Nix profile; QT vars remain present.

### `nix eval --option eval-cache false --json '.#nixosConfigurations.axiom.config.systemd.user.services."caelestia-shell".environment'`
- **Why**: Verifies Caelestia service still receives the same QT environment from the new shared constants helper.
- **Result**: PASS.
- **Observed**: `QT_QPA_PLATFORM=wayland;xcb`, `QT_QPA_PLATFORMTHEME=qtengine`, `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`, `QT_AUTO_SCREEN_SCALE_FACTOR=1`.

### Axiom/Azar service path evals
- **Commands**:
- `nix eval --raw '.#nixosConfigurations.axiom.config.systemd.services."opencode-server".environment.HOME'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.systemd.services."opencode-server".serviceConfig.WorkingDirectory'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.systemd.services."opencode-server".serviceConfig.ExecStart'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.systemd.services."autossh-reverse-ssh".environment.HOME'`
- `nix eval --raw '.#nixosConfigurations.azar.config.systemd.services."autossh-reverse-ssh".environment.HOME'`
- **Why**: Proves hardcoded `/home/c1` replacements evaluate to the same service/user paths.
- **Result**: PASS.
- **Observed**: `/home/c1`; opencode command remains `/home/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096`.

### Charlie/Charles Darwin path evals
- **Commands**:
- `nix eval --json '.#darwinConfigurations.charlie.config.launchd.user.agents."opencode-server".serviceConfig.ProgramArguments'`
- `nix eval --raw '.#darwinConfigurations.charlie.config.launchd.user.agents."opencode-server".serviceConfig.WorkingDirectory'`
- `nix eval --raw '.#darwinConfigurations.charlie.config.launchd.user.agents."opencode-server".serviceConfig.StandardOutPath'`
- `nix eval --raw '.#darwinConfigurations.charlie.config.modules.agenix.sshKey'`
- `nix eval --raw '.#darwinConfigurations.charles.config.users.users.c1.home'`
- **Why**: Proves Darwin path normalization keeps launchd command, user home, log path and agenix key path equivalent.
- **Result**: PASS.
- **Observed**: `/Users/c1/.opencode/bin/opencode`, `/Users/c1`, `/Users/c1/Library/Logs/opencode-server.out.log`, `/Users/c1/.ssh/id_ed25519`.

### Helper non-import check
- **Command**: `nix eval --option eval-cache false --impure --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/hlissner-architecture-cleanup"; in flake.nixosConfigurations.axiom.config ? waylandSessionVariables'`
- **Why**: Verifies `_env.nix` is not accidentally loaded as a module by recursive discovery.
- **Result**: PASS.
- **Observed**: `false`.

### `nix build --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`
- **Why**: Strongest affordable local validation for the representative Linux desktop host without building/deploying.
- **Result**: PASS.
- **Observed**: Nix planned 23 derivations and did not report evaluation failures.

## Runtime Smoke Still Needed After Deployment
- Axiom: start/restart Hyprland + Caelestia session, launcher/sidebar, terminal/browser launch, OSD/media/brightness, screenshot/recording, lock, wallpaper, network/polkit controls.
- Darwin: shell env, opencode launchd agent, cloudflared/opencode route if the PR is deployed to Charlie.
