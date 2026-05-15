# Axiom Hyprland DPMS Safe Mode Fix

## Goal

Stop the Axiom desktop from dropping into Hyprland safe mode when the display turns off, resumes, or the monitor hotplug path is exercised, and make the related idle actions resolve their declared commands from the systemd user service.

## Problem

The user reports that turning off the screen reliably makes Caelestia crash and then enter safe mode. Runtime logs show a different primary failure chain: Hyprland 0.53.3 crashes during the DPMS/suspend resume monitor hotplug path, then Caelestia exits because the Wayland compositor connection disappears. Hyprland's restart path then launches `Hyprland --safe-mode`, which presents as the desktop entering safe mode.

The same log window also shows `hypridle` trying to run `hyprctl dispatch dpms ...` and `hyprlock`, but the systemd user service PATH only contains a minimal systemd/coreutils path. That means the configured lock/DPMS commands are not reliably executable from the idle daemon even before addressing the upstream Hyprland crash.

## Acceptance

- [ ] The task records evidence that the observed safe mode is caused by Hyprland crashing before Caelestia exits, not by Caelestia being the root crashing process.
- [ ] Axiom's Hyprland config disables the affected color-management pipeline while the pinned Hyprland 0.53.3 build is in use.
- [ ] `hypridle.service` has an explicit runtime PATH that can resolve `hyprctl`, `hyprlock`, `pidof`, `systemctl`, and `loginctl` for the checked-in `hypridle.conf` commands.
- [ ] Focused Nix/static checks prove the generated Axiom Hyprland config contains `render.cm_enabled = false` and the generated hypridle service PATH includes the required tools.
- [ ] Axiom toplevel build passes, or the strongest feasible blocker is recorded.
- [ ] The final report states the remaining live-session validation needed after deploy.

## Assumptions

- The active Axiom crash corresponds to the captured 2026-05-15 00:20 resume event, where Hyprland generated coredumps and Caelestia logged a broken Wayland connection.
- The current pinned Hyprland package is `v0.53.3` and includes the upstream color-management crash signature seen in `NColorManagement::CImageDescription::id()`.
- A local mitigation is acceptable until the pinned Hyprland package advances to a version containing the upstream fix.
- The immediate task is a repository-owned mitigation and evidence trail, not an upstream Hyprland patch.

## Constraints

- Use the Legion workflow and implement inside `.worktrees/axiom-hyprland-dpms-safe-mode-fix/`.
- Keep scope to Axiom/Hyprland idle and compositor crash mitigation.
- Do not patch upstream Hyprland or Caelestia source in this task.
- Do not change authentication, polkit power permissions, suspend policy, secrets, or remote-access services.
- Do not touch the main workspace's unrelated untracked `token.env`.

## Risks

- Disabling Hyprland color management can affect HDR or color-managed rendering quality until the upstream fix lands.
- Static checks cannot prove DPMS/suspend resume stability; a deployed live-session smoke is still required.
- The running host may not yet have all repository changes deployed, so runtime service availability can lag behind the repo state.

## Scope

- `hosts/axiom/default.nix`
- `modules/desktop/hyprland.nix`
- `.legion/tasks/axiom-hyprland-dpms-safe-mode-fix/**`
- `.legion/wiki/**` entries that need current-truth updates for this mitigation

## Non-Goals

- Do not update the flake lock or switch Axiom to Hyprland git in this task.
- Do not remove Caelestia or redesign the shell session.
- Do not run destructive live suspend or poweroff tests during this session.
- Do not make system-wide/headless sleep-policy changes.
- Do not claim the upstream crash is fixed; this task only mitigates it locally.

## Design Summary

Use a narrow Axiom mitigation instead of a broad compositor package update: set `render.cm_enabled = false` through Axiom's generated Hyprland extra config, and make `hypridle.service` declare the tools required by the existing idle commands. This targets the captured failure path while preserving the existing Hyprland/UWSM/Caelestia ownership model.

## Design-Lite

The chosen path is small and reversible. The upstream crash signature is already known against Hyprland 0.53.x color-management/hotplug handling, and the Hyprland 0.53 wiki documents `render.cm_enabled` as a supported kill switch requiring restart. The hypridle PATH change is mechanical service hygiene matching the commands already present in `config/hypr/hypridle.conf`. Rollback is a git revert; operationally, color management can be re-enabled after Hyprland is updated and live DPMS/resume smoke passes.

## Phases

1. Brainstorm: materialize the task contract and design-lite from log evidence.
2. Engineer: apply the Axiom Hyprland color-management mitigation and hypridle PATH fix.
3. Verify Change: run focused Nix/static checks and Axiom build where feasible.
4. Review Change: assess correctness, scope, and residual display-stack risk.
5. Report Walkthrough: produce reviewer-facing summary.
6. Legion Wiki: update current decisions/patterns/maintenance with the mitigation and live validation requirement.
