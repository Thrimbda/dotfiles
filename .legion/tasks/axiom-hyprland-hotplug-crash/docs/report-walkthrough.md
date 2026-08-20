# Delivery Walkthrough: Axiom Hyprland Hotplug XWayland Crash Fix

**Mode:** implementation

## Outcome

Axiom now builds Hyprland 0.56.1 with a local guard for the confirmed crash path: an XWayland floating target mapped while its workspace temporarily has no monitor. Instead of dereferencing the missing monitor, Hyprland uses the cached floating work-area origin and emits a warning.

## What Changed

- `hosts/axiom/default.nix` imports one Axiom-only guard module.
- `hosts/axiom/modules/hyprland-hotplug-guard.nix` asserts version `0.56.1` and appends the local patch through `programs.hyprland.package`.
- `hosts/axiom/modules/hyprland-xwayland-floating-monitor-guard.patch` guards `CDefaultFloatingAlgorithm::newTarget` without changing normal monitor-backed placement.

## Verification

- The patch applies with zero fuzz to the pinned v0.56.1 source.
- The patched Hyprland package compiles successfully.
- The final Axiom closure builds successfully at `/nix/store/8q22c48r8dhq8ifmc8hzcmbwww5mpabv-nixos-system-axiom-26.05.7813.0dd31db7e6db`.
- The final debug-source overlay contains the fallback and warning.
- XWayland, monitor hotplug, DP-4, and DP-5 at scale 1.5 remain enabled in the evaluated configuration.

## Scope and Rollback

The package override is Axiom-only. It does not change flake inputs, portal packaging, display definitions, or hotplug policy. Remove the Axiom guard-module import to return to the shared unpatched package selection.

## Remaining Limit

No live switch, restart, hotplug, DPMS, or forced XWayland map was run. A future approved physical smoke should verify the fallback warning appears when applicable and that Hyprland does not coredump or restart in safe mode.
