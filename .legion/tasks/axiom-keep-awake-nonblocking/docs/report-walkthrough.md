# Walkthrough: Axiom Keep Awake Nonblocking Startup

Mode: implementation

## Problem

The 60-second retry window from PR #59 fixes the Caelestia cold-start IPC race, but the helper was still launched in the foreground from `07-caelestia-keep-awake`. If startup hooks run sequentially, that can delay later startup work and feel like the shell is slower.

## Change

- Updated `07-caelestia-keep-awake` to launch the existing helper via `nohup` in the background.
- Preserved the helper's direct `caelestia-shell ipc call idleInhibitor enable` command.
- Preserved the 120 retry attempts from the race fix.
- Kept the old custom no-sleep layer absent.

## Validation

- Targeted Nix assertions passed for `nohup`, backgrounding, output suppression, startup hook ordering, direct IPC, 120 retries, and old wrapper absence.
- `git diff --check` passed.
- Axiom toplevel build passed.

## Deployment Note

After deploying, start a fresh Hyprland session and confirm two things: shell startup is no longer delayed by Keep Awake waiting, and `caelestia shell idleInhibitor isEnabled` reports enabled after Caelestia IPC is ready.
