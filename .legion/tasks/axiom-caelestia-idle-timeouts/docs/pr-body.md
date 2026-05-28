## Summary

- Align Caelestia's Axiom `general.idle.timeouts` with Hypridle at 15 minute lock and 30 minute DPMS.
- Remove Caelestia's upstream 10 minute automatic idle sleep action from Axiom-owned settings.
- Migrate existing mutable Caelestia `shell.json` on session startup so deployed configs get the same policy.

## Verification

- `git diff --check`
- Targeted `nix eval --impure --json --expr '...'` assertions for Caelestia settings, migration helper text, and Hypridle policy
- Focused automatic sleep searches in `hosts/axiom` and `config/hypr`
- jq migration filter syntax check
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes

- Live idle/suspend tests were intentionally skipped to avoid disrupting the active desktop session.
- Post-deploy, restart the Hyprland/Caelestia session and confirm `~/.config/caelestia/shell.json` contains only the 900/1800 idle timeouts.
