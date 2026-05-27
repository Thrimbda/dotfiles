# Axiom Caelestia Never Sleep Default

Status: Superseded by `axiom-remove-never-sleep`
Task: `.legion/tasks/axiom-caelestia-never-sleep-default/`
Branch: `legion/axiom-caelestia-never-sleep-default-sleep-inhibitor`

## Summary

This historical task kept the visible Caelestia Keep Awake state enabled and added a session-scoped login1 sleep blocker so the workstation defaulted to never sleeping while the graphical session was active. It is no longer current behavior after `axiom-remove-never-sleep`.

## Root Cause

The earlier Caelestia Keep Awake default only enabled Caelestia `idleInhibitor`. Runtime feedback showed Axiom could still sleep, so the idle-inhibitor-only design did not satisfy the stronger default never-sleep requirement.

## Historical Outcome

- `07-caelestia-keep-awake` remains backgrounded and continues to enable Caelestia `idleInhibitor` through direct `caelestia-shell` IPC with the cold-start retry window.
- Axiom declared `axiom-caelestia-never-sleep.service`, a user service wanted by and `PartOf=` `hyprland-session.target`.
- The service runs the generated `axiom-caelestia-never-sleep` script, which executes `systemd-inhibit --what=sleep --who="Axiom Caelestia" --why="Axiom Caelestia session defaults to never sleep" --mode=block` with a long-running `tail -f /dev/null` child.
- The old custom `axiom-sleep-mode` wrapper, Power Mode launchers, and Axiom-only Hypridle override remain absent.
- `hosts/axiom/README.org` documented the live checks and the current-session escape hatch: `systemctl --user stop axiom-caelestia-never-sleep.service`.

## Validation

- Targeted Nix shape assertions passed for the session service, restart policy, Keep Awake startup hook, and absence of `axiom-sleep-mode`.
- `git diff --check` passed.
- Axiom toplevel build passed and built `axiom-caelestia-never-sleep.drv`, `unit-axiom-caelestia-never-sleep.service.drv`, and the Axiom system derivation.
- Post-build script assertions passed for `caelestia-shell ipc call idleInhibitor enable`, `seq 1 120`, `systemd-inhibit`, `--what=sleep`, `--mode=block`, and `tail -f /dev/null`.

## Boundary

This was a graphical-session policy. It did not enforce pre-login/headless no-sleep behavior and did not grant logind `ignore-inhibit` or widen polkit power actions. The active Axiom policy no longer includes this service.

## Follow-Up

Historical live graphical-session smoke was:

```sh
caelestia shell idleInhibitor isEnabled
systemctl --user status axiom-caelestia-never-sleep.service
systemd-inhibit --list | grep -i 'Axiom Caelestia'
```

## Supersedes

Supersedes the weaker idle-inhibitor-only enforcement assumption from `axiom-caelestia-keep-awake-default`, `axiom-caelestia-keep-awake-race-fix`, and `axiom-keep-awake-nonblocking` for the default never-sleep requirement. Those tasks remain current for Caelestia IPC startup timing and nonblocking hook behavior.
