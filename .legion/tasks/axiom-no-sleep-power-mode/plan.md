# Axiom No Sleep Power Mode

## Goal

Make Axiom default to a no-sleep desktop power mode while preserving an explicit desktop-controlled way to switch back to an allow-sleep mode.

## Problem

Axiom's current Hyprland desktop starts `hypridle`, and the checked-in `config/hypr/hypridle.conf` can suspend the machine after idle time. That is a bad default for this workstation because remote access, long-running desktop work, downloads, and service processes should not be interrupted by unattended automatic sleep. At the same time, the user does not want sleep support deleted entirely: the desktop should still expose a deliberate way to toggle between no-sleep and sleep-allowed behavior.

## Acceptance

- [ ] Axiom boots into a default no-sleep behavior for the Hyprland/Caelestia desktop; unattended idle should not auto-suspend by default.
- [ ] The no-sleep default is scoped to `axiom` and does not silently change sleep policy for other hosts.
- [ ] The desktop session has a repository-managed toggle path that can switch between no-sleep and allow-sleep behavior without editing files by hand.
- [ ] The allow-sleep mode keeps the existing lock/DPMS/suspend intent available when explicitly selected.
- [ ] Generated Axiom config or targeted evaluation proves the relevant Hypridle/systemd/logind settings and toggle artifacts are present.
- [ ] Axiom toplevel build or the strongest feasible Nix validation passes; any local blocker is recorded with evidence.
- [ ] Verification, readiness review, walkthrough, wiki writeback, and PR lifecycle evidence are recorded.

## Assumptions

- Axiom is the only host requested for this behavior.
- The desired default is no automatic suspend from the graphical idle path, not disabling user-initiated shutdown/reboot/suspend actions entirely.
- The desktop toggle can be implemented as a small repository-managed command/action exposed to the Hyprland/Caelestia session; it does not need a custom graphical settings panel in this task.
- Manual suspend should remain possible when the user explicitly chooses an allow-sleep mode or directly invokes a session power action.
- Live idle timeout testing is disruptive and may remain a post-deploy smoke test if no live Axiom graphical session is available.

## Constraints

- Follow Legion workflow and use the git-worktree PR envelope for production changes.
- Keep changes focused on Axiom power/idle behavior.
- Do not broaden polkit power permissions beyond the existing reviewed Axiom-local allowlist unless an RFC explicitly justifies it.
- Do not redesign Caelestia quick controls or implement a full UI panel in this task.
- Do not change laptop-oriented power policy, other hosts, or global desktop defaults unless required to support an Axiom-scoped override.

## Risks

- Disabling automatic suspend incorrectly could also block intentional manual suspend or lock-before-sleep behavior.
- A runtime toggle must coordinate with `hypridle` reliably; stale daemon state could make the selected mode unclear without an explicit state file or restart/reload behavior.
- Static validation can prove generated config and scripts, but cannot fully prove long idle behavior without a live Axiom Hyprland session.
- Power/session behavior is disruptive to test, so verification must avoid causing an unwanted suspend in this tool session.

## Scope

- `hosts/axiom/default.nix` for Axiom-specific default policy and host-local wiring.
- `modules/desktop/hyprland.nix` and/or `config/hypr/hypridle.conf` if a reusable idle-mode hook or generated config is the smallest correct implementation.
- Repository-managed helper/action files only if needed for desktop mode switching.
- `.legion/tasks/axiom-no-sleep-power-mode/**` for design, verification, review, and delivery evidence.

## Non-Goals

- Do not remove sleep/hibernate capability from NixOS globally.
- Do not disable user-triggered shutdown, reboot, suspend, or hibernate actions from the existing session UI.
- Do not build a new Caelestia settings panel or redesign the quick controls surface.
- Do not tune CPU governor, GPU power management, fan curves, display brightness, or other unrelated power-performance settings.
- Do not perform live suspend or reboot tests unless explicitly safe in the active environment.

## Design Summary

Default Axiom to a no-sleep idle mode by making the generated desktop idle behavior host-controllable rather than relying on the static imported `hypridle.conf` suspend listener. Preserve the previous sleep-capable behavior as an explicit allow-sleep mode and expose a small desktop-safe toggle path, likely through a fixed command/action that updates user-local state and restarts or reloads `hypridle`. Because this crosses generated config, runtime session state, and power behavior, the implementation should first record a short RFC with options, rollback, and validation.

## Design Index

Design source of truth: `docs/rfc.md`.

The RFC selects an Axiom-local `axiom-sleep-mode` command, desktop launcher entries, a generated Axiom Hypridle override, and a user sleep-inhibitor service. The global Hypridle source stays unchanged for other hosts.

## Phases

1. Brainstorm: materialize stable task contract.
2. Design Gate: write and review a short RFC for no-sleep default plus desktop toggle semantics.
3. Engineer: implement the reviewed minimal declarative/session changes in an isolated worktree.
4. Verify Change: run focused Nix/static validation without triggering disruptive suspend.
5. Review Change: assess readiness, scope, and power/session safety.
6. Report Walkthrough: produce reviewer-facing summary and PR body.
7. Legion Wiki: write durable task summary and reusable power/idle notes.
8. PR Lifecycle: commit, push, create/track PR, clean up worktree, and refresh the main workspace after terminal state.

---

Created: 2026-05-14
