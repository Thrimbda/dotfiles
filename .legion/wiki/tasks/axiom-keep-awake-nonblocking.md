# Axiom Keep Awake Nonblocking Startup

Status: PR-backed implementation pending
Task: `.legion/tasks/axiom-keep-awake-nonblocking/`
Branch: `legion/axiom-keep-awake-nonblocking`

## Summary

Kept Axiom's 60-second Caelestia Keep Awake cold-start retry window but moved the wait out of the foreground startup hook path.

## Root Cause

The race fix made `axiom-caelestia-keep-awake` wait up to about 60 seconds for Caelestia IPC, but `07-caelestia-keep-awake` still ran it in the foreground. If startup hooks execute sequentially, that wait can block later startup work and make shell startup feel slower.

## Effective Outcome

- `07-caelestia-keep-awake` now launches the existing helper with `nohup ... &` and redirects output to `/dev/null`.
- The helper still calls `${caelestia-shell}/bin/caelestia-shell ipc call idleInhibitor enable` directly.
- The helper still retries 120 times with 0.5 second sleeps for cold-start IPC registration.
- The old custom `axiom-sleep-mode` wrapper remains absent.
- The behavior remains graphical-session scoped and uses Caelestia's Keep Awake UI as source of truth.

## Validation

- Targeted Nix assertions passed for `nohup`, backgrounding, output suppression, hook ordering, direct helper command text, 120 retry attempts, and old wrapper absence.
- `git diff --check` passed.
- Axiom toplevel build passed.

## Follow-Up

After deploying the fixed generation, start a new Hyprland session, confirm startup is no longer delayed by Keep Awake waiting, and confirm `caelestia shell idleInhibitor isEnabled` reports enabled once Caelestia IPC is ready.
