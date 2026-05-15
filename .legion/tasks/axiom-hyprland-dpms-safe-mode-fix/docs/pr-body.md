## Summary

- Diagnose the reported Caelestia safe-mode crash as a Hyprland 0.53.3 DPMS/resume color-management crash, not a Caelestia-first crash.
- Disable Hyprland color management on Axiom with `render.cm_enabled = false` until the pinned Hyprland package includes the upstream fix.
- Add the required command PATH to `hypridle.service` so existing lock/DPMS commands resolve under systemd user execution.

## Validation

- `nix eval --impure --json --expr '<focused generated-config assertions>'`
- `git diff --check`
- `nix build --no-link ".#nixosConfigurations.axiom.config.system.build.toplevel"`
- Assembled Axiom `Hyprland --verify-config --config <generated-config>`

## Live Follow-Up

- After deploy, restart the Axiom graphical session and exercise DPMS off/on or suspend/resume.
- Confirm no new Hyprland coredump, no `--safe-mode` restart, and no Caelestia broken-Wayland exit.
