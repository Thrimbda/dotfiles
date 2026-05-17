# Walkthrough: Axiom Caelestia Never Sleep Default

Mode: implementation

## Summary

- Axiom now keeps Caelestia's visible Keep Awake state enabled and adds `axiom-caelestia-never-sleep.service` as the enforcement layer for the stronger default.
- The new user service is scoped to `hyprland-session.target` and runs `systemd-inhibit --what=sleep --mode=block`, so sleep is blocked while the graphical Hyprland/Caelestia session is active.
- Host docs now include live checks for Caelestia Keep Awake, the user service, and `systemd-inhibit --list`, plus the current-session stop command.

## Why This Change

The previous Axiom default only retried `caelestia-shell ipc call idleInhibitor enable`. Runtime feedback showed Axiom could still sleep, so the idle-inhibitor-only design was not sufficient for the requested never-sleep default. The reviewed RFC selected a session-scoped sleep inhibitor because it blocks sleep at the login1 boundary without restoring the old custom `axiom-sleep-mode` launcher/toggle system.

Evidence: `docs/rfc.md`, `docs/review-rfc.md`.

## Production Changes

- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`

Implementation details:

- Added `axiom-caelestia-never-sleep`, a generated script that executes `systemd-inhibit --what=sleep --who="Axiom Caelestia" --why="Axiom Caelestia session defaults to never sleep" --mode=block` with `tail -f /dev/null` as the long-running child.
- Added `systemd.user.services.axiom-caelestia-never-sleep`, wanted by, ordered after, and `PartOf=` `hyprland-session.target`.
- Preserved the existing backgrounded `07-caelestia-keep-awake` startup hook and direct Caelestia shell IPC helper.
- Updated Axiom README to describe the stronger never-sleep default and live validation commands.

## Validation

Validation passed:

- Targeted Nix shape assertions passed.
- `git diff --check` passed.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.
- Post-build script assertions passed, proving the exact Caelestia Keep Awake helper and sleep inhibitor script contents.

Evidence: `docs/test-report.md`.

## Review

Readiness review passed with no blocking findings.

Review highlights:

- Scope is Axiom-local.
- No global Hypridle, other host, upstream Caelestia QML, polkit, or `axiom-sleep-mode` changes were introduced.
- Security lens found no privilege expansion; the service blocks sleep in the user's graphical session and accepts no user-controlled input.

Evidence: `docs/review-change.md`.

## Residual Risk And Follow-Up

- Post-deploy live smoke is still required on Axiom: `caelestia shell idleInhibitor isEnabled`, `systemctl --user status axiom-caelestia-never-sleep.service`, and `systemd-inhibit --list | grep -i 'Axiom Caelestia'`.
- Manual suspend from the active graphical session is intentionally blocked by default until the user stops `axiom-caelestia-never-sleep.service` or ends the session.
- This remains a graphical-session policy, not a pre-login/headless no-sleep policy.
