# Axiom Caelestia Keep Awake Default

Status: PR-backed implementation pending
Task: `.legion/tasks/axiom-caelestia-keep-awake-default/`
Branch: `legion/axiom-caelestia-keep-awake-default-reuse`

## Summary

Replaced the custom Axiom no-sleep mode with Caelestia's built-in Keep Awake / `idleInhibitor` capability and enabled it by default when the Axiom graphical session starts.

## Effective Outcome

- `axiom-sleep-mode`, `Power Mode:*` launchers, `axiom-no-sleep-inhibit.service`, `axiom-sleep-mode-apply.service`, and the Axiom-only direct Hypridle override are removed.
- Axiom now has `axiom-caelestia-keep-awake.service`, a user oneshot under `hyprland-session.target` that retries `caelestia shell idleInhibitor enable` after `caelestia-shell.service` starts.
- Caelestia's own Keep Awake UI is the source of truth for the visible toggle.
- `hosts/axiom/README.org` documents `caelestia shell idleInhibitor isEnabled|enable|disable|toggle` and the graphical-session boundary.

## Validation

Static validation passed for targeted Nix assertions, stale wrapper grep under `hosts/axiom`, `git diff --check`, and the Axiom NixOS toplevel build.

## Boundary

This is graphical-session scoped. If Axiom is headless or the Caelestia shell fails to start, Keep Awake is not a system-wide no-sleep policy.

## Supersedes

Supersedes the implementation details of `.legion/wiki/tasks/axiom-no-sleep-power-mode.md`; that task remains historical evidence for the original custom-wrapper approach.
