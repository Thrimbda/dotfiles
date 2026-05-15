# Walkthrough: Axiom Caelestia Keep Awake Default

Mode: implementation

## Summary

- Replaces the custom Axiom no-sleep mode with Caelestia's built-in Keep Awake / `idleInhibitor` capability.
- Enables Keep Awake automatically when the Axiom Hyprland/Caelestia session starts.
- Keeps Caelestia's own Keep Awake UI as the visible toggle and removes separate Power Mode launcher entries.

## What Changed

Production files:

- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`

Implementation details:

- Removed `axiom-sleep-mode` and its `no-sleep` / `allow-sleep` / `toggle` state system.
- Removed `Power Mode: No Sleep`, `Power Mode: Allow Sleep`, and `Power Mode: Toggle Sleep` desktop launchers.
- Removed the Axiom-only `hypr/hypridle.conf` override that routed suspend through `axiom-sleep-mode maybe-suspend`.
- Removed `axiom-no-sleep-inhibit.service` and `axiom-sleep-mode-apply.service`.
- Added `axiom-caelestia-keep-awake.service`, a user oneshot service under `hyprland-session.target` that retries `caelestia shell idleInhibitor enable` after `caelestia-shell.service` starts.
- Added `hosts/axiom/README.org` documenting the Caelestia shell entrypoints and graphical-session boundary.

## Why

Caelestia already has a Keep Awake UI backed by `services/IdleInhibitor.qml` and IPC verbs such as `caelestia shell idleInhibitor enable`. Using that native capability keeps the UI state and actual idle-inhibit behavior aligned, while avoiding a second Axiom-specific mode state.

## Verification

`docs/test-report.md` records PASS for:

- Targeted Nix assertions proving the new service is present, tied to `hyprland-session.target`, depends on `caelestia-shell.service`, and the old wrapper/package/services/direct Hypridle override are absent.
- Host-level stale wrapper grep under `hosts/axiom`.
- `git diff --check`.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.

## Review

`docs/review-change.md` verdict is PASS.

Security lens was applied because this touches power/session behavior. The review found no blocker: the change removes a custom sleep-inhibitor service, does not widen polkit, does not grant logind `ignore-inhibit`, and keeps behavior in Caelestia's user session boundary.

## Live Follow-Up

After deployment on Axiom:

- Confirm `caelestia shell idleInhibitor isEnabled` reports enabled after login.
- Confirm Caelestia's Keep Awake UI shows enabled by default.
- Confirm toggling the UI changes the same state.
- Remember this is graphical-session scoped, not a headless/system-wide sleep policy.
