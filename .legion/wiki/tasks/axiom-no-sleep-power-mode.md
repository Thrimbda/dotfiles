# Axiom No-Sleep Power Mode

Status: historical; superseded by `axiom-caelestia-keep-awake-default`
Task: `.legion/tasks/axiom-no-sleep-power-mode/`
Branch: `legion/axiom-no-sleep-power-mode-default-toggle`

## Summary

Added an Axiom-local desktop power mode so the workstation defaults to no-sleep while still allowing the user to switch back to sleep-allowed behavior from the desktop.

## Superseded

The custom `axiom-sleep-mode` command, Power Mode launcher entries, Axiom Hypridle override, and user sleep-inhibitor service were superseded by `axiom-caelestia-keep-awake-default`, which reuses Caelestia's built-in Keep Awake / `idleInhibitor` capability and keeps the shell UI as the source of truth.

## Effective Outcome

- Axiom owns a new `axiom-sleep-mode` command with fixed verbs: `no-sleep`, `allow-sleep`, `toggle`, `apply`, `maybe-suspend`, and `status`.
- Axiom user packages include desktop launcher entries for no-sleep, allow-sleep, and toggle mode.
- Axiom overrides only its generated `hypr/hypridle.conf`; the global `config/hypr/hypridle.conf` remains unchanged for other hosts.
- In no-sleep mode, Hypridle's suspend timeout calls `axiom-sleep-mode maybe-suspend`, which skips automatic suspend.
- In no-sleep mode, `axiom-no-sleep-inhibit.service` runs a user `systemd-inhibit --what=sleep --mode=block` process so direct sleep requests are also blocked unless the user switches to allow-sleep.
- `axiom-sleep-mode-apply.service` runs with `hyprland-session.target` to apply the selected mode when the graphical session starts.

## Validation

Static validation passed:

- Targeted Nix assertions for generated Hypridle text, unchanged global Hypridle source, inhibitor service, apply service, script package, and launcher package count.
- `git diff --check`.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.

## Security And Scope

The change does not widen polkit power permissions and does not grant logind `ignore-inhibit`. It is scoped to `hosts/axiom/default.nix` and keeps other hosts on the existing Hypridle config.

## Remaining Live Validation

After deployment on Axiom, confirm `axiom-sleep-mode status`, launcher switching, `systemd-inhibit --list`, lock/DPMS behavior, no-sleep idle behavior, and allow-sleep suspend behavior in the real Hyprland session.
