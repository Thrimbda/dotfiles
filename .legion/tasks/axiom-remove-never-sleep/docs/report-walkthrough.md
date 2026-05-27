# Axiom Remove Never Sleep - Walkthrough

Mode: implementation

## Summary

- Removed Axiom's generated `axiom-caelestia-never-sleep` script and `axiom-caelestia-never-sleep.service` user service.
- Preserved Caelestia Keep Awake startup enablement through the existing `idleInhibitor` helper.
- Preserved the user's Hypridle timing change: lock after 15 minutes and DPMS off after 30 minutes.
- Updated active README and wiki current-truth guidance so the removed service is no longer described as current behavior.

## What Changed

### Axiom Host Config

`hosts/axiom/default.nix` no longer creates the `axiom-caelestia-never-sleep` script and no longer declares `systemd.user.services.axiom-caelestia-never-sleep`.

The existing `axiom-caelestia-keep-awake` helper remains, including its direct `caelestia-shell ipc call idleInhibitor enable` behavior.

### Hypridle Policy

`config/hypr/hypridle.conf` now reflects the user's updated idle timing:

- `timeout = 900 # 15mins` for lock.
- `timeout = 1800 # 30mins` for DPMS off/on.
- No automatic suspend command/listener is present.

### Documentation And Wiki

`hosts/axiom/README.org` now describes Hypridle as the idle lock/display-power owner and states that direct sleep requests are not blocked by a repository-owned sleep-inhibitor service.

`.legion/wiki/decisions.md`, `.legion/wiki/patterns.md`, and `.legion/wiki/maintenance.md` were updated to reflect the current policy. The previous `axiom-caelestia-never-sleep-default` task summary is explicitly marked superseded, while retained as historical evidence.

## Verification

Evidence is recorded in `docs/test-report.md`.

- Active-reference search found no current host config, Hypridle config, README, or current-truth wiki references to the removed service/script.
- Hypridle grep confirmed the 15 minute lock and 30 minute DPMS settings.
- `git diff --check` passed.
- Targeted Nix eval confirmed no `axiom-caelestia-never-sleep` user service, preserved `idleInhibitor enable`, no suspend command in Hypridle, and the expected timeout values.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

## Review

Review evidence is recorded in `docs/review-change.md`.

Verdict: PASS, no blocking findings.

Security lens: considered because the task touches logind-adjacent power behavior. No blocker found; the change removes a default sleep blocker without broadening polkit/logind permissions.

## Residual Risk

- Live Hyprland/Caelestia runtime behavior still needs post-deploy smoke in the actual Axiom graphical session.
- Suggested post-deploy checks: `caelestia shell idleInhibitor isEnabled`, active Hypridle config/logs, and absence of a repository-owned sleep-inhibitor user service.
