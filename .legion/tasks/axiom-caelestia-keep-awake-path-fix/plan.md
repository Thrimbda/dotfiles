# Axiom Caelestia Keep Awake Path Fix

## Goal

Fix the deployed regression where `axiom-caelestia-keep-awake.service` fails at session startup and therefore does not enable Caelestia Keep Awake by default.

## Problem

Runtime evidence on Axiom showed the user service is enabled but failed with:

```text
FileNotFoundError: [Errno 2] No such file or directory: 'caelestia-shell'
```

The service invokes the Caelestia Python CLI by absolute path, but that CLI shells out to `caelestia-shell` by name. The generated oneshot unit has a minimal NixOS service `PATH`, so the subprocess lookup fails before the IPC call can reach the running shell.

## Scope

- Update the Axiom Keep Awake helper to avoid relying on ambient `PATH` for `caelestia-shell`.
- Preserve Caelestia Keep Awake / `idleInhibitor` as the source of truth.
- Preserve the graphical-session-scoped behavior.
- Update validation and wiki evidence for the regression.

## Out Of Scope

- Restoring `axiom-sleep-mode`, Power Mode launchers, custom Hypridle overrides, or `systemd-inhibit` wrappers.
- Changing Caelestia UI behavior.
- Adding headless/system-wide no-sleep policy.
- Widening polkit or logind permissions.

## Acceptance

- Evaluated Axiom config still contains `axiom-caelestia-keep-awake.service` under `hyprland-session.target` and `caelestia-shell.service` wiring.
- The generated helper script calls the evaluated Caelestia shell binary by absolute Nix store path, not `caelestia shell ...` through a `PATH`-dependent subprocess.
- The old custom sleep mode remains absent.
- `git diff --check` and the Axiom toplevel build pass.

## Risk

Low. The change is limited to the startup helper command path for an already-existing user oneshot service.
