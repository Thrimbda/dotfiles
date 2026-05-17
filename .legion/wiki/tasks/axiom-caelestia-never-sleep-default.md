# Axiom Caelestia Never Sleep Default

Status: PR-backed implementation pending
Task: `.legion/tasks/axiom-caelestia-never-sleep-default/`
Branch: `legion/axiom-caelestia-never-sleep-default-sleep-inhibitor`

## Summary

Axiom's Caelestia desktop now keeps the visible Caelestia Keep Awake state enabled and adds a session-scoped login1 sleep blocker so the workstation defaults to never sleeping while the graphical session is active.

## Root Cause

The earlier Caelestia Keep Awake default only enabled Caelestia `idleInhibitor`. Runtime feedback showed Axiom could still sleep, so the idle-inhibitor-only design did not satisfy the stronger default never-sleep requirement.

## Effective Outcome

- `07-caelestia-keep-awake` remains backgrounded and continues to enable Caelestia `idleInhibitor` through direct `caelestia-shell` IPC with the cold-start retry window.
- Axiom now declares `axiom-caelestia-never-sleep.service`, a user service wanted by and `PartOf=` `hyprland-session.target`.
- The service runs the generated `axiom-caelestia-never-sleep` script, which executes `systemd-inhibit --what=sleep --who="Axiom Caelestia" --why="Axiom Caelestia session defaults to never sleep" --mode=block` with a long-running `tail -f /dev/null` child.
- The old custom `axiom-sleep-mode` wrapper, Power Mode launchers, and Axiom-only Hypridle override remain absent.
- `hosts/axiom/README.org` now documents the live checks and the current-session escape hatch: `systemctl --user stop axiom-caelestia-never-sleep.service`.

## Validation

- Targeted Nix shape assertions passed for the session service, restart policy, Keep Awake startup hook, and absence of `axiom-sleep-mode`.
- `git diff --check` passed.
- Axiom toplevel build passed and built `axiom-caelestia-never-sleep.drv`, `unit-axiom-caelestia-never-sleep.service.drv`, and the Axiom system derivation.
- Post-build script assertions passed for `caelestia-shell ipc call idleInhibitor enable`, `seq 1 120`, `systemd-inhibit`, `--what=sleep`, `--mode=block`, and `tail -f /dev/null`.

## Boundary

This is a graphical-session policy. It does not enforce pre-login/headless no-sleep behavior and does not grant logind `ignore-inhibit` or widen polkit power actions. Manual suspend from the active graphical session is intentionally blocked by default until the service or session is stopped.

## Follow-Up

After deployment on Axiom, run a live graphical-session smoke:

```sh
caelestia shell idleInhibitor isEnabled
systemctl --user status axiom-caelestia-never-sleep.service
systemd-inhibit --list | grep -i 'Axiom Caelestia'
```

## Supersedes

Supersedes the weaker idle-inhibitor-only enforcement assumption from `axiom-caelestia-keep-awake-default`, `axiom-caelestia-keep-awake-race-fix`, and `axiom-keep-awake-nonblocking` for the default never-sleep requirement. Those tasks remain current for Caelestia IPC startup timing and nonblocking hook behavior.
