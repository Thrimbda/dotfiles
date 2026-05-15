# Test Report

## Summary

PASS. Targeted Nix evaluation confirms the generated Hyprland keybind for `axiom` now launches `foot -e tmux new-session -A -s main`, while the global terminal environment and helper variables remain unchanged.

## Commands

- `nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/keybinds.conf".text'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/env.conf".text'`
- `nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/variables.conf".text'`
- `git diff --check`

## Evidence

- `keybinds.conf` contains `bind = SUPER+SHIFT, Return, exec, foot -e tmux new-session -A -s main`.
- `env.conf` still contains `env = TERMINAL,foot`.
- `variables.conf` still contains `$terminal = foot` and `$taskManager = foot -e htop`.
- `git diff --check` produced no whitespace errors.

## Why These Checks

- The change affects generated Hyprland config, so evaluating the exact generated home config is more direct than a broad build.
- The acceptance criteria require proving only the shortcut changes, so `env.conf` and `variables.conf` evaluation checks that global terminal behavior did not drift.

## Skipped

- Full `nixos-rebuild switch` was not run because this task only needs to prove the generated config shape and live activation depends on the target desktop session.
