# Axiom Second Monitor Workspaces

## Status

Implementation reviewed and ready for PR delivery.

## Summary

Axiom now has an explicit second-monitor workspace set. Workspaces 1..10 remain on the primary monitor and keep the existing `SUPER+1..0` / `SUPER+SHIFT+1..0` bindings. Workspaces 11..20 are generated for the configured secondary monitor `DP-5` and get `SUPER+ALT+1..0` / `SUPER+ALT+SHIFT+1..0` bindings.

The behavior is behind `modules.desktop.hyprland.workspaces.secondary.enable`, defaulting to false, and is enabled only for Axiom so other multi-monitor hosts do not inherit the 11..20 workspace model unexpectedly.

## Evidence

- Axiom `workspaces.conf` evaluates with `$SECONDARY_MONITOR = DP-5` and `workspace=11..20,monitor:$SECONDARY_MONITOR`.
- Axiom `keybinds.conf` evaluates with `SUPER+ALT+1..0` and `SUPER+ALT+SHIFT+1..0` bindings.
- Existing ALT bindings only use non-numeric keys such as `R` and `S`; no numeric conflicts were found.
- `azar` workspace config was evaluated as a regression check and remains limited to workspace 1..10.
- Home Manager activation package builds and `git diff --check` passes.

## Current Decisions

- Preserve Axiom primary workspace muscle memory on `SUPER+1..0`.
- Use `SUPER+ALT+1..0` for second-monitor workspace 11..20 rather than splitting the first ten workspaces across monitors.
- Keep second-monitor workspace generation opt-in at the host/module level.

## Follow-Up

- After deployment, reload Hyprland and confirm `SUPER+ALT+1` focuses workspace 11 on DP-5.
- If Caelestia bar does not show workspace 11..20, handle that separately as a Caelestia workspace-display task.
