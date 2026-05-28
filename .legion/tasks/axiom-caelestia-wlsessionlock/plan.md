# Axiom Caelestia WlSessionLock

## Goal

Remove Axiom's repository-owned `hyprlock` lock-screen path and make ordinary idle/keybind lock requests use Caelestia's native WlSessionLock surface through the existing Caelestia shell IPC.

## Problem

Axiom has moved to Caelestia as the active product shell, and the shell already ships a `WlSessionLock` implementation exposed as `caelestia shell lock lock`. The current repository still installs `hyprlock`, declares `security.pam.services.hyprlock`, generates a `SUPER+SHIFT+L` binding to `hyprlock`, keeps Hypridle pointed at `hyprlock`, and carries obsolete hyprlock config/helpers. That keeps two lock clients in active policy and contradicts the requested single Caelestia lock surface.

## Acceptance

- Axiom idle and keybind lock paths call `caelestia shell lock lock` rather than `hyprlock`, `pidof hyprlock`, or `loginctl lock-session`.
- `hyprlock` is no longer installed by the Hyprland module for Axiom and no `security.pam.services.hyprlock` service is declared.
- Repository-owned Hyprlock config and helper scripts under `config/hypr` are removed or made non-active.
- `hey .lock` remains a compatibility entrypoint for existing callers but delegates to Caelestia WlSessionLock.
- Axiom README and Legion wiki current-truth entries describe Caelestia WlSessionLock as the active lock path.
- Focused static and Nix validation pass, with live Hyprland lock/unlock smoke recorded as post-deploy follow-up.

## Scope

- `modules/desktop/hyprland.nix` lock package, PAM, service PATH, shortcut help, and generated keybinds.
- `config/hypr/hypridle.conf` and local lock helper scripts.
- Axiom host README/config comments and Legion wiki current-truth writeback.

## Non-Goals

- Do not redesign Caelestia's QML lock surface or PAM files.
- Do not route normal locks through `loginctl lock-session`.
- Do not change idle timing, DPMS timing, sleep policy, or Keep Awake semantics beyond replacing the lock client.
- Do not preserve Hyprlock styling flags as compatibility behavior; they no longer apply when Caelestia owns the lock surface.

## Assumptions

- The pinned Caelestia shell exposes the `lock` IPC target with `lock`, `unlock`, and `isLocked` commands.
- The generated session runner keeps Caelestia inside the graphical session so Quickshell IPC is reachable after startup.
- Hypridle's systemd user service can resolve `caelestia` and `caelestia-shell` through its explicit service `PATH`.

## Constraints

- The change must not reintroduce a foreground startup lock gate.
- The change must not widen polkit/logind privileges.
- Headless validation cannot prove actual Wayland lock/unlock behavior; live Axiom session smoke remains required after deployment.

## Risks

- If Caelestia is not running or IPC is unavailable when Hypridle fires, the lock command may fail instead of falling back to Hyprlock.
- Live WlSessionLock rendering, keyboard focus, and PAM unlock behavior cannot be fully proven by Nix evaluation.
- Existing manual uses of `hey .lock` styling flags become no-ops because Caelestia owns presentation.

## Recommended Direction

Use the Caelestia CLI IPC path everywhere ordinary Axiom lock requests originate: generated keybinds, Hypridle, and the compatibility `hey .lock` wrapper. Remove Hyprlock package/config/PAM wiring entirely so future validation cannot silently pass through the old lock client.

## Phases

- Implement the lock-route switch and remove Hyprlock artifacts.
- Validate generated keybinds, service PATH, Axiom toplevel build, PAM absence, closure absence, and static references.
- Review the change for lock/security regressions.
- Record walkthrough and wiki writeback, then deliver through PR.
