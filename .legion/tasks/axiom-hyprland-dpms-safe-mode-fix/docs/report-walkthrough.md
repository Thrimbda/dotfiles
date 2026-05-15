# Axiom Hyprland DPMS Safe Mode Fix - Walkthrough

Mode: implementation

## Summary

- Diagnosed the reported Caelestia safe-mode crash as a Hyprland compositor crash during DPMS/suspend resume, followed by Caelestia exiting after its Wayland connection broke.
- Added an Axiom-only Hyprland mitigation: `render.cm_enabled = false` while the pinned Hyprland 0.53.3 build carries the color-management hotplug crash signature.
- Added an explicit `hypridle.service` PATH so the existing lock/DPMS commands can resolve `hyprctl`, `hyprlock`, `pidof`, `systemctl`, and `loginctl` from the user service.

## Evidence Trail

- Runtime logs showed Caelestia's failure after compositor loss: `The Wayland connection broke. Did the Wayland compositor die?` followed by `caelestia-shell.service` exit.
- `coredumpctl` showed Hyprland coredumps at the same event, including a safe-mode restart command line.
- Hyprland crash report showed `NColorManagement::CImageDescription::id()` during DRM hotplug/resume, matching upstream Hyprland 0.53.x reports.
- Hypridle logs showed `hyprctl: not found` and `hyprlock: not found`, proving the service PATH was insufficient for existing idle commands.

## Changed Files

- `hosts/axiom/default.nix`: injects `render { cm_enabled = false }` through Axiom Hyprland extra config.
- `modules/desktop/hyprland.nix`: adds `path = [ config.programs.hyprland.package pkgs.unstable.hyprlock pkgs.procps pkgs.systemd ]` to `hypridle.service`.
- `.legion/tasks/axiom-hyprland-dpms-safe-mode-fix/**`: records contract, design-lite, validation, and review evidence.

## Validation

`docs/test-report.md` records PASS for:

- Focused generated-config eval proving `cmDisabled`, `renderBlockPresent`, `hasHyprland`, `hasHyprlock`, `hasProcps`, and `hasSystemd` are all true.
- `git diff --check`.
- `nix build --no-link ".#nixosConfigurations.axiom.config.system.build.toplevel"`.
- Assembled Axiom `Hyprland --verify-config`, which returned `config ok`.

## Review

`docs/review-change.md` records PASS with no blocking findings. Security lens was applied because the change touches session/power-adjacent behavior; no privileged path, polkit, secret, auth, or trust-boundary issue was found.

## Residual Live Check

Static validation cannot prove the physical DPMS/suspend path. After deploy, restart the Axiom graphical session, trigger DPMS off/on or suspend/resume, then confirm:

- No new Hyprland coredump appears in `coredumpctl list`.
- Hyprland does not restart with `--safe-mode`.
- `caelestia-shell.service` does not exit with a broken Wayland connection.
