# Walkthrough: Axiom Caelestia Keep Awake Race Fix

Mode: implementation

## Problem

After the direct IPC path fix, Axiom still did not always show Keep Awake enabled by default. The current generation no longer uses `caelestia-shell.service`; PR #58 moved shell ownership to the session-owned `caelestia-session` runner.

## Cause

The startup hooks run in the intended order, but `caelestia-session start` backgrounds the shell runner and returns before Quickshell IPC is registered. In the observed live session, `hyprland-session.target` became active around `19:39:42`, while the Caelestia shell instance registered at `19:39:53`. The helper retried for about 10 seconds, so it could miss normal cold-start registration by about one second and then fail silently behind `|| true`.

## Change

- Increased `axiom-caelestia-keep-awake` retry attempts from `20` to `120`.
- This changes the wait window from about 10 seconds to about 60 seconds.
- Kept direct `caelestia-shell ipc call idleInhibitor enable` usage.
- Kept Caelestia Keep Awake / `idleInhibitor` as the UI source of truth.

## Validation

- Runtime diagnosis confirmed session-owned Caelestia launch and the observed 11-second IPC registration gap.
- Manual helper smoke in the live graphical session returned `true` after enabling.
- Targeted Nix assertions passed for startup hook ordering, direct IPC usage, 120 retry attempts, and old wrapper absence.
- `git diff --check` passed.
- Axiom toplevel build passed.

## Deployment Note

After deploying the generation, start a fresh Hyprland session or restart `caelestia-session`, then confirm `caelestia shell idleInhibitor isEnabled` reports enabled once Caelestia finishes cold startup.
