# Axiom Dynamic Monitor Hotplug

## Status

Implementation reviewed and ready for PR delivery.

## Summary

Axiom display handling now uses a cohesive monitor inventory under `modules.desktop.hyprland.monitors`. Known displays carry output fallbacks, identity hints, layout, scale, fallback mode, and `native-max-refresh` policy in one place.

The generated startup config remains conservative and explicit: DP-4 starts as `3840x2160@240` and DP-5 starts as `3840x2160@60`. Runtime reconciliation then inspects live Hyprland modes and chooses the native/highest-resolution mode with the highest refresh at that resolution. Unknown hotplug displays on Axiom use the same native-max-refresh policy with auto position and scale 1.5, so a 4K120 display should use 4K120 rather than dropping to a lower-resolution 240Hz mode.

Caelestia per-monitor support is co-located with the monitor inventory through optional `monitor.caelestia.settings`. Axiom currently declares no concrete per-monitor Caelestia overrides, preserving existing mutable global `shell.json` behavior while avoiding a separate scattered config surface.

## Evidence

- Generated `hypr/monitors.conf` evaluates to explicit DP-4 4K240 and DP-5 4K60 rules.
- `modules.desktop.hyprland.monitorHotplug` evaluates with unknown outputs enabled for `native-max-refresh`, `position = auto`, and `scale = 1.5`.
- Home Manager activation package and NixOS system toplevel build without switching the system.
- Generated reconcile helper and event watcher pass `bash -n`.
- Static mode-selection sample outputs `HDMI-A-1,3840x2160@120.00,auto,1.5` for an unknown 4K120 display with a lower-resolution 240Hz mode also available.
- `docs/review-change.md` records PASS after fixing a Caelestia seed-helper temp-file cleanup issue.

## Current Decisions

- Axiom monitor facts and display policy should stay in the cohesive Hyprland monitor inventory, not split across ad-hoc host scripts and separate Caelestia config snippets.
- Unknown Axiom hotplug outputs should use native/highest-resolution first, then highest refresh at that resolution.
- Caelestia per-monitor overrides should use upstream's `~/.config/caelestia/monitors/<screen-name>/shell.json` path, but should be seeded from monitor inventory only when explicitly declared.

## Follow-Up

- After deploy, restart Hyprland or log out/in and confirm `hyprland-monitor-hotplug.service` is active.
- Confirm DP-4 is 4K240 and DP-5 is 4K60 in `hyprctl monitors all -j`.
- Test a physical 4K120 hotplug display when available.
- If Hyprland/Aquamarine atomic commit failures recur, treat a clean Hyprland restart as the fallback rather than repeated reconcile attempts.
