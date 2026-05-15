# Axiom Hyprland DPMS Safe Mode Fix

Status: Implementation verified, live deployment smoke pending
Task: `.legion/tasks/axiom-hyprland-dpms-safe-mode-fix/`
Branch: `legion/axiom-hyprland-dpms-safe-mode-fix`

## Summary

Investigated the reported "turning off the screen makes Caelestia crash and enter safe mode" incident. Runtime logs and coredumps show Hyprland crashes first during DPMS/suspend resume monitor hotplug handling, then Caelestia exits because the Wayland compositor connection broke. Hyprland's restart path then runs in safe mode.

## Effective Outcome

- Axiom injects `render { cm_enabled = false }` into generated Hyprland config as a local mitigation for the pinned Hyprland 0.53.3 color-management hotplug crash.
- `hypridle.service` now has explicit PATH coverage for Hyprland, hyprlock, procps, and systemd so checked-in idle commands can resolve `hyprctl`, `hyprlock`, `pidof`, `systemctl`, and `loginctl`.
- The task does not patch Caelestia, update Hyprland, widen polkit power permissions, or change secrets/auth/remote access.

## Validation

- Focused Nix eval proved `cmDisabled`, `renderBlockPresent`, `hasHyprland`, `hasHyprlock`, `hasProcps`, and `hasSystemd`.
- `git diff --check` passed.
- Axiom NixOS toplevel build passed.
- Assembled generated Hyprland config passed `Hyprland --verify-config` with `config ok`.

## Boundary

This is a mitigation, not an upstream fix. Static checks cannot prove physical display-off/resume stability; after deployment, live DPMS/resume smoke must confirm no new Hyprland coredump, no `--safe-mode` restart, and no Caelestia broken-Wayland exit.

## Follow-Up

After the pinned Hyprland package includes the upstream color-management hotplug fix, remove the Axiom `render.cm_enabled = false` override and repeat live DPMS/resume validation.
