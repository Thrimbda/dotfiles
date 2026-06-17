# Research

## Current Repository Shape

- `modules.desktop.hyprland.monitors` is the existing monitor fact surface. It generates `hypr/monitors.conf`, `hypr/workspaces.conf`, exposes `hey.info.hypr.monitors`, and is already consumed by Steam scale integration.
- Axiom currently uses `hosts/axiom/default.nix` for host-local monitor facts. The emergency fix changed the previous wildcard monitor rule into explicit `DP-4` and `DP-5` rules.
- `config/hypr/bin/set-monitors.zsh` already reads `hey info hypr monitors` and applies known monitor rules, but it is manual and not EDID/mode-policy driven.
- `modules.desktop.caelestia` owns the Caelestia session runner, seeds mutable global `~/.config/caelestia/shell.json`, and exposes `session.preStart` for narrow mutable migrations.
- Axiom already has a host-local `ensureCaelestiaSettings` pre-start script that merges required idle and launcher settings into mutable `shell.json` with `jq`.

## Upstream Caelestia Config Facts

- Global shell settings live in `~/.config/caelestia/shell.json`.
- Per-monitor overrides live in `~/.config/caelestia/monitors/<screen-name>/shell.json`.
- Per-monitor files override global settings only for supported options.
- Some global-only options are ignored in per-monitor files, including `general.idle`, many launcher options, some bar workspace internals, services fields, paths, and lock options.
- The upstream Home Manager module exists, but this repository intentionally uses a local NixOS module and mutable seeded shell state rather than handing lifecycle ownership to upstream.

## Live Incident Facts

- Axiom has two connected displays in the active session: `DP-4` Microstep MPG272UX OLED and `DP-5` Dell U2720QM.
- The old wildcard monitor rule could apply `3840x2160@240` to any output, including displays that do not support 240Hz.
- After DPMS/hotplug activity, Hyprland/Aquamarine logged repeated `atomic drm request: failed to commit: Invalid argument` and `DP-5` remained stuck at `640x480@59.93` in the live session.
- No Hyprland coredump was recorded for this incident; the failure mode is bad runtime output state rather than a process crash.

## Design Implications

- The runtime helper should be idempotent and conservative. It can avoid bad static rules and choose better modes, but it cannot fix a compositor/driver state after atomic commits are already failing.
- `modules.desktop.hyprland.monitors` is the best existing high-cohesion surface for monitor policy because it already feeds Hyprland, workspace, and related desktop consumers.
- Caelestia per-monitor config should be generated or seeded from the same monitor entries, not separately hard-coded in Axiom host scripts.
