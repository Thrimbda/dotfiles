## Summary

- Add an Axiom-local, local-primary-user polkit allowlist for selected NetworkManager Wi-Fi/profile actions and logind power actions used by the Caelestia/Quickshell shell.
- Remove Catppuccin from current visible Axiom theme surfaces by disabling the Fcitx5 Catppuccin override and switching Autumnal icons/cursors to Papirus/Bibata.

## Validation

- `nix eval --impure --json --expr '<aggregated Axiom config assertions>'`
- `git diff --check`
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`

## Notes

- Live Wi-Fi/power actions were not triggered from this tool session because they are disruptive.
- Post-deploy smoke should confirm Caelestia control behavior, Thunar icons, and Fcitx5 candidate UI in the switched graphical session.
