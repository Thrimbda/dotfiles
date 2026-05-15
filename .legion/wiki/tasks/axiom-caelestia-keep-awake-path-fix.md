# Axiom Caelestia Keep Awake Path Fix

Status: implemented; followed by `axiom-caelestia-keep-awake-race-fix` for session-runner cold-start timing
Task: `.legion/tasks/axiom-caelestia-keep-awake-path-fix/`
Branch: `legion/axiom-caelestia-keep-awake-path-fix`

## Summary

Fixed the deployed Axiom Keep Awake default regression where `axiom-caelestia-keep-awake.service` failed before enabling Caelestia `idleInhibitor`.

## Root Cause

The helper called the Caelestia Python CLI by absolute path, but that CLI runs `caelestia-shell` by name. The generated oneshot unit had a minimal NixOS service `PATH`, so the subprocess lookup failed with `FileNotFoundError: 'caelestia-shell'` even though `caelestia-shell.service` and `hyprland-session.target` were active.

## Effective Outcome

- `axiom-caelestia-keep-awake` now calls `${caelestia-shell}/bin/caelestia-shell ipc call idleInhibitor enable` directly.
- The existing retry loop and `hyprland-session.target` / `caelestia-shell.service` wiring remain in place.
- The old custom `axiom-sleep-mode` wrapper remains absent.
- The behavior remains graphical-session scoped and uses Caelestia's Keep Awake UI as source of truth.

## Validation

- Runtime diagnosis confirmed the failed service root cause.
- Manual direct IPC enabled the current live session and `isEnabled` returned `true`.
- Targeted Nix assertions passed for service wiring, direct helper command text, and old wrapper absence.
- `git diff --check` passed.
- Axiom toplevel build passed.

## Follow-Up

After the later session-runner migration, use `axiom-caelestia-keep-awake-race-fix` for the current default-enable timing behavior.
