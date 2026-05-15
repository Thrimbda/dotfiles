# Axiom Hyprland DPMS Safe Mode Fix - Design-Lite

## Context

Runtime evidence points to a compositor failure rather than a Caelestia-first crash. When the display-off/resume path was exercised, Hyprland 0.53.3 generated coredumps in the color-management output image-description path. Caelestia then reported a broken Wayland connection and exited, and Hyprland's watchdog/safe-mode restart made the user-visible result look like Caelestia crashed into safe mode.

## Options

1. Disable Hyprland color management on Axiom until the pinned Hyprland package advances.
2. Update or override Hyprland to a git revision containing the upstream fix.
3. Patch Hyprland/Aquamarine source locally.

## Decision

Choose option 1 for this task. It is the smallest repository-owned mitigation, uses a documented Hyprland setting, avoids a broad compositor package/lockfile change, and is easy to revert after an upstream Hyprland update.

Also fix the hypridle service PATH in the reusable Hyprland module. This is not the root coredump, but the same logs show existing lock/DPMS commands failing because service PATH lacks `hyprctl` and `hyprlock`.

## Verification

- Evaluate generated Axiom Hyprland config and assert it contains `render { cm_enabled = false }`.
- Evaluate `systemd.user.services.hypridle.path` and assert it includes Hyprland, hyprlock, procps, and systemd tools.
- Build the Axiom toplevel if feasible.
- Record that final proof requires a deployed live Hyprland session smoke: restart the session, trigger DPMS off/on or suspend/resume, then check for absence of new Hyprland coredumps and absence of `--safe-mode` restart.

## Rollback

Revert this task's commit. Operationally, after Hyprland is updated past the upstream fix, remove the Axiom `render.cm_enabled = false` override and repeat live DPMS/resume smoke.
