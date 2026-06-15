# Axiom 4K 240Hz HDR Display

## Status

Implementation reviewed and ready for PR delivery.

## Summary

Axiom's Hyprland monitor rule now requests `3840x2160@240` instead of `3840x2160@60`, addressing the user's current 60Hz display state as the highest-priority goal. The existing position `0x0` and fractional scale `1.5` remain unchanged.

The shared Hyprland monitor module now accepts optional HDR/color-management fields: `bitdepth`, `cm`, `sdrbrightness`, and `sdrsaturation`. Existing hosts that do not set these fields continue to generate the legacy `monitor = output,mode,position,scale` form. A configured advanced monitor generates a `monitorv2` block.

HDR is not enabled by default for Axiom in this task. `render.cm_enabled = false` remains in place because it is the current mitigation for Hyprland 0.53.x color-management crashes on DPMS/resume. HDR should only become runtime-active after color management is deliberately re-enabled and verified on the real Axiom session.

## Evidence

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/monitors.conf".text'` produced `monitor = ,3840x2160@240,0x0,1.500000`.
- `git diff --check` passed.
- `azar` monitor output still used legacy `monitor = ...` lines, proving default behavior for non-HDR hosts did not change.
- A temporary `extendModules` override with `output = "DP-1"`, `bitdepth = 10`, `cm = "hdr"`, `sdrbrightness = 1.2`, and `sdrsaturation = 0.98` generated a `monitorv2` block.
- `docs/review-change.md` recorded PASS with no blocking findings and no security trigger.

## Current Decisions

- 240Hz is the priority over HDR for Axiom display work.
- Axiom should not claim runtime HDR while `render.cm_enabled = false` remains active.
- Future HDR enablement requires a live DPMS/resume smoke after re-enabling Hyprland color management.

## Follow-Up

- Deploy Axiom and run `hyprctl monitors` in the real Hyprland session to confirm the active display reports `3840x2160@240`.
- If still capped at 60Hz, inspect the output name and advertised modes before expanding scope to cable, port, NVIDIA, kernel, or EDID work.
- Revisit HDR only after the color-management crash mitigation can be safely removed.
