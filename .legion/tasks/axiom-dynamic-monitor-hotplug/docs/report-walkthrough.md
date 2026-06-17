# Report Walkthrough

Mode: implementation.

## What Changed

- Extended `modules.desktop.hyprland.monitors` into a cohesive monitor inventory with dynamic mode policy, fallback mode, identity matching, and optional Caelestia per-monitor settings.
- Updated Axiom monitor facts so DP-4 and DP-5 are explicit known displays with identity hints and `native-max-refresh` policy.
- Added Axiom unknown-output handling so newly plugged displays use native/highest-resolution first and highest refresh at that resolution, with auto position and scale 1.5.
- Generated a `hyprland-reconcile-monitors` helper from the inventory and wired it into startup/reload hooks.
- Added a Hyprland-session-scoped event watcher that listens to the Hyprland event socket and debounces monitor events before reconciliation.
- Added Caelestia per-monitor seed support from the same monitor entries while preserving mutable global `shell.json` ownership.

## Reviewer Notes

- Startup baseline remains safe and explicit: DP-4 gets `3840x2160@240`; DP-5 gets `3840x2160@60`; no wildcard 240Hz rule is generated.
- Unknown 4K120 displays are handled by runtime reconciliation, not by static wildcard rules.
- Caelestia per-monitor support is implemented as opt-in `monitor.caelestia.settings`; Axiom currently declares no concrete per-monitor overrides, so no user-visible Caelestia monitor behavior changes are introduced.
- The watcher is user-session scoped and can be rolled back independently from static monitor config.

## Verification Evidence

- `nix eval` confirms generated `hypr/monitors.conf` is explicit DP-4/DP-5 only.
- `nix eval` confirms monitor hotplug options and monitor inventory.
- Home Manager activation package builds.
- NixOS system toplevel builds.
- Generated reconcile helper and hotplug watcher pass `bash -n`.
- Static jq sample confirms unknown 4K120 selects `3840x2160@120.00`, while the known OLED selects `3840x2160@240.00`.
- `git diff --check` passes.

## Rollback

- Disable `modules.desktop.hyprland.monitorHotplug.enable` to remove the runtime reconcile hook and watcher.
- Set monitor entries back to static modes if dynamic mode selection causes trouble.
- Remove any future `monitor.caelestia.settings` entries to stop seeding per-monitor Caelestia files.
- Restart Hyprland if the compositor is already in a bad atomic modeset state.

## Residual Risk

This does not fix Hyprland/Aquamarine/NVIDIA atomic commit failures. If the compositor reaches that failure mode, a clean Hyprland restart may still be required.
