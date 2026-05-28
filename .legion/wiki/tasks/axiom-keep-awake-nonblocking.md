# Axiom Keep Awake Nonblocking Startup

Status: historical; superseded by `axiom-remove-default-keep-awake`
Task: `.legion/tasks/axiom-keep-awake-nonblocking/`
Branch: `legion/axiom-keep-awake-nonblocking`

## Summary

This historical task kept Axiom's 60-second Caelestia Keep Awake cold-start retry window but moved the wait out of the foreground startup hook path. It is no longer current behavior after `axiom-remove-default-keep-awake`, which removed default Keep Awake startup enablement entirely.

## Root Cause

The race fix made `axiom-caelestia-keep-awake` wait up to about 60 seconds for Caelestia IPC, but `07-caelestia-keep-awake` still ran it in the foreground. If startup hooks execute sequentially, that wait can block later startup work and make shell startup feel slower.

## Historical Outcome

- `07-caelestia-keep-awake` launched the existing helper with `nohup ... &` and redirected output to `/dev/null`.
- The helper called `${caelestia-shell}/bin/caelestia-shell ipc call idleInhibitor enable` directly.
- The helper retried 120 times with 0.5 second sleeps for cold-start IPC registration.
- The old custom `axiom-sleep-mode` wrapper remains absent.
- This behavior was graphical-session scoped and used Caelestia's Keep Awake UI as source of truth until `axiom-remove-default-keep-awake` removed default startup enablement.

## Validation

- Targeted Nix assertions passed for `nohup`, backgrounding, output suppression, hook ordering, direct helper command text, 120 retry attempts, and old wrapper absence.
- `git diff --check` passed.
- Axiom toplevel build passed.

## Follow-Up

For current behavior, use `axiom-remove-default-keep-awake`: start a new Hyprland session and confirm Axiom does not force `caelestia shell idleInhibitor isEnabled` back to enabled.
