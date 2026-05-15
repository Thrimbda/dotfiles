# Axiom Caelestia Keep Awake Race Fix

Status: PR-backed implementation pending
Task: `.legion/tasks/axiom-caelestia-keep-awake-race-fix/`
Branch: `legion/axiom-caelestia-keep-awake-race-fix`

## Summary

Fixed the remaining Axiom Keep Awake default-enable race after Caelestia moved from `caelestia-shell.service` to the session-owned `caelestia-session` runner.

## Root Cause

`caelestia-session start` backgrounds the runner and returns before the Quickshell IPC instance is necessarily registered. In the observed session, `hyprland-session.target` started around `19:39:42`, while the Caelestia instance registered at `19:39:53`. The existing helper retried for about 10 seconds, so it could miss normal cold-start IPC registration and then fail silently behind `|| true`.

## Effective Outcome

- `axiom-caelestia-keep-awake` now retries 120 times with 0.5 second sleeps, giving about 60 seconds for Caelestia IPC registration.
- The helper still calls `${caelestia-shell}/bin/caelestia-shell ipc call idleInhibitor enable` directly.
- The `06-caelestia-shell` then `07-caelestia-keep-awake` startup hook order remains unchanged.
- The old custom `axiom-sleep-mode` wrapper remains absent.
- The behavior remains graphical-session scoped and uses Caelestia's Keep Awake UI as source of truth.

## Validation

- Runtime diagnosis confirmed the session-owned shell launch and observed IPC registration gap.
- Manual helper smoke in the live graphical session returned `true` after enabling.
- Targeted Nix assertions passed for hook ordering, direct helper command text, 120 retry attempts, and old wrapper absence.
- `git diff --check` passed.
- Axiom toplevel build passed.

## Follow-Up

After deploying the fixed generation, restart `caelestia-session` or start a new Hyprland session, then confirm `caelestia shell idleInhibitor isEnabled` reports enabled once Caelestia finishes cold startup.
