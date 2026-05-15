# Axiom Hyprland DPMS Safe Mode Fix - Log

## Session Progress (2026-05-15)

### Completed

- Entered Legion workflow because the user explicitly requested Legion workflow for a multi-step desktop crash investigation.
- Created task `axiom-hyprland-dpms-safe-mode-fix` because no explicit task directory was provided and the issue is distinct from the earlier Caelestia Keep Awake task.
- Opened isolated worktree `.worktrees/axiom-hyprland-dpms-safe-mode-fix/` on branch `legion/axiom-hyprland-dpms-safe-mode-fix` from `origin/master`.
- Collected runtime logs from `caelestia-shell.service`, `hypridle.service`, `systemd-logind`, coredumpctl, and the Hyprland crash report.
- Identified the primary failure chain: Hyprland crashed at resume/hotplug, Caelestia exited after the Wayland connection broke, and Hyprland restarted in safe mode.
- Materialized plan/tasks/design-lite in the task directory and read them back.
- Implemented the local mitigation: Axiom now injects `render { cm_enabled = false }` into generated Hyprland config.
- Implemented the service hygiene fix: `hypridle.service` now declares a PATH containing Hyprland, hyprlock, procps, and systemd.
- Engineer smoke eval passed for `cmDisabled`, `hasHyprland`, `hasHyprlock`, `hasProcps`, and `hasSystemd`.
- Verification completed with PASS in `docs/test-report.md`: focused generated-config eval, `git diff --check`, Axiom toplevel build, and assembled `Hyprland --verify-config` all passed.
- Readiness review completed with PASS in `docs/review-change.md`; security lens found no privileged path, polkit, secret, auth, or trust-boundary change.
- Generated reviewer-facing walkthrough and PR body in `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Legion wiki writeback completed for current decisions, patterns, maintenance, task summary, index, and wiki log.

### Key Evidence

- `journalctl --user -u caelestia-shell.service --since "-12 hours"` shows `qt.qpa.wayland: Could not create EGL surface`, `The Wayland connection broke. Did the Wayland compositor die?`, and `caelestia-shell.service` exiting at 2026-05-15 00:20:33.
- `coredumpctl list --since "-12 hours"` shows Hyprland coredumps at 2026-05-15 00:20:32 and 00:20:51, including a second run with command line `Hyprland --watchdog-fd 4 --safe-mode`.
- `/home/c1/.cache/hyprland/hyprlandCrashReport2451.txt` shows Hyprland v0.53.3 crashing in `NColorManagement::CImageDescription::id()` after DRM hotplug scanning for DP-5.
- `journalctl --user -u hypridle.service -u hyprland-session.target --since "-12 hours"` shows `hyprlock: not found` and `hyprctl: not found` for lock/DPMS commands because the service PATH is minimal.
- External upstream discussion `hyprwm/Hyprland#12871` matches the `CImageDescription::id()` wake/hotplug crash signature and reports it fixed on Hyprland git after v0.53.x.
- Hyprland 0.53 variables document `render.cm_enabled` as the color-management pipeline kill switch.

### In Progress

- Git/PR lifecycle: commit branch, rebase on `origin/master`, push, open/update PR, and follow required checks/review.

### Blockers

- Live DPMS/suspend-resume validation requires deploying the change into the real Axiom graphical session and intentionally exercising the display-off/resume path.

## Decisions

| Decision | Reason | Alternative | Date |
|---|---|---|---|
| Treat Hyprland as the primary crashing process | Coredumps and crash report precede Caelestia's broken Wayland connection. | Patch or restart Caelestia first. | 2026-05-15 |
| Disable Hyprland color management on Axiom as a local mitigation | The crash stack is in Hyprland color-management hotplug handling, and `render.cm_enabled` is the documented restart-scoped kill switch. | Update to Hyprland git or patch upstream source. | 2026-05-15 |
| Fix hypridle service PATH in the reusable module | Checked-in `hypridle.conf` calls `hyprctl`, `hyprlock`, `pidof`, `systemctl`, and `loginctl`; service units must not rely on interactive shell PATH. | Rewrite `hypridle.conf` with store paths. | 2026-05-15 |
