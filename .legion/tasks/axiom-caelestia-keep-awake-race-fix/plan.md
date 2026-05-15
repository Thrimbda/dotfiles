# Axiom Caelestia Keep Awake Race Fix

## Goal

Fix the remaining Axiom Keep Awake default-enable race after Caelestia moved from `caelestia-shell.service` to the session-owned `caelestia-session` launcher.

## Problem

Runtime evidence showed the current Axiom generation starts Caelestia through `caelestia-session run`, not `caelestia-shell.service`. The host startup hooks evaluate as:

```text
06-caelestia-shell       caelestia-session start
07-caelestia-keep-awake  axiom-caelestia-keep-awake || true
```

`caelestia-session start` backgrounds the runner and returns before the Quickshell IPC instance is registered. In the observed session, `hyprland-session.target` started around `19:39:42`, while the Caelestia instance launch time was `19:39:53`. The existing Keep Awake helper only retried for about 10 seconds, so it could miss a normal cold start by about one second and fail silently behind `|| true`.

## Scope

- Increase the Axiom Keep Awake helper retry window so it covers Caelestia session cold starts.
- Preserve direct `caelestia-shell ipc call idleInhibitor enable` usage.
- Preserve Caelestia Keep Awake UI as the source of truth and keep the behavior graphical-session scoped.
- Update validation and wiki evidence.

## Out Of Scope

- Restoring `caelestia-shell.service`.
- Reintroducing `axiom-sleep-mode`, Power Mode launchers, custom Hypridle overrides, or `systemd-inhibit` wrappers.
- Changing Caelestia UI behavior.
- Adding headless/system-wide no-sleep policy.
- Widening polkit or logind permissions.

## Acceptance

- Evaluated startup hooks still order Caelestia session startup before Axiom Keep Awake.
- The generated Keep Awake helper uses direct Caelestia shell IPC and retries long enough for a normal cold shell startup.
- The old custom sleep mode remains absent.
- `git diff --check`, targeted `nix eval`, and the Axiom toplevel build pass.

## Risk

Low. The change only extends retry timing for an idempotent `idleInhibitor enable` IPC call.
