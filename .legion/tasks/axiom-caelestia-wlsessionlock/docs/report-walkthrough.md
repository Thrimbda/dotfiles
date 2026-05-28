# Axiom Caelestia WlSessionLock - Walkthrough

Mode: implementation

## Summary

- Replaced Axiom's ordinary Hyprlock-based lock paths with Caelestia's native WlSessionLock IPC command.
- Removed active Hyprlock package, PAM, config, and helper-script ownership from the repository.
- Updated Axiom docs and Legion wiki current truth so future lock work starts from Caelestia WlSessionLock.

## What Changed

### Hyprland Module

`modules/desktop/hyprland.nix` now defines `caelestiaLockCommand = "${caelestiaCli} shell lock lock"` and uses it for the generated `SUPER+SHIFT+L` binding. The shortcut help now describes Caelestia WlSessionLock.

The module no longer declares Hyprlock options, installs `pkgs.unstable.hyprlock`, or creates `security.pam.services.hyprlock`.

`hypridle.service.path` now includes the evaluated Caelestia CLI and shell packages instead of Hyprlock/procps/systemd for the lock path.

### Hypridle And Helpers

`config/hypr/hypridle.conf` sets `$lock_cmd = caelestia shell lock lock`, so idle lock and before-sleep lock use the same Caelestia IPC path.

`config/hypr/bin/lock.zsh` remains as a compatibility entrypoint for existing `hey .lock` callers, but it delegates to `caelestia shell lock lock` and intentionally ignores legacy Hyprlock styling flags.

`config/hypr/hooks/idle.zsh` no longer applies Hyprlock-specific Nvidia redraw workarounds or checks `pidof hyprlock`.

### Removed Files

- `config/hypr/hyprlock.conf`
- `config/hypr/hyprlock/check-capslock.sh`
- `config/hypr/hyprlock/status.sh`

### Documentation And Wiki

`hosts/axiom/README.org` now documents Caelestia WlSessionLock as the lock path.

`.legion/wiki/decisions.md`, `.legion/wiki/patterns.md`, `.legion/wiki/maintenance.md`, `.legion/wiki/log.md`, and `.legion/wiki/tasks/axiom-caelestia-wlsessionlock.md` record the new current truth and live follow-up checks.

## Verification

Evidence is recorded in `docs/test-report.md`.

- Edited zsh scripts pass syntax validation.
- Generated keybinds evaluate with `SUPER+SHIFT+L` calling the Caelestia CLI store path plus `shell lock lock`.
- `hypridle.service.path` evaluates with Hyprland, Caelestia CLI, and Caelestia shell packages.
- Axiom toplevel eval and build pass.
- Axiom closure has no `hyprlock` path.
- `security.pam.services.hyprlock` evaluates to absent.
- Active module/config/host reference searches no longer find Hyprlock outside historical Legion records.
- `git diff --check` passes.

## Review

Review evidence is recorded in `docs/review-change.md`.

Verdict: PASS, no blocking findings.

## Residual Risk

- Run a live Axiom Hyprland/Caelestia smoke after deployment: `caelestia shell lock lock`, unlock, `SUPER+SHIFT+L`, and Hypridle-triggered lock.
- If Caelestia IPC is unavailable, the lock command fails rather than falling back to Hyprlock; this is intentional for the Caelestia-only requirement.
