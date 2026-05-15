## Summary

- Hydrate missing display/session variables for Caelestia Shell from the systemd user manager so launcher children like Steam can connect to XWayland.
- Keep the import limited to a fixed display allowlist and preserve existing PATH, Qt, and Hyprland session behavior.
- Verified the current live session: Caelestia/Quickshell now have `DISPLAY=:0`, and Steam no longer logs the prior `XOpenDisplay failed` error.

## Validation

- PASS: `git diff --check`
- PASS: `nix eval --impure --raw '.#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.controlCommand'`
- PASS: `nix build --impure --print-out-paths --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'`
- PASS: `bash -n /nix/store/nfwivzy55yc02ib1dlclxadr3qs3ywgm-caelestia-session/bin/caelestia-session`
- PASS: live Caelestia restart and launcher-like Steam smoke test cleared the X display failure
