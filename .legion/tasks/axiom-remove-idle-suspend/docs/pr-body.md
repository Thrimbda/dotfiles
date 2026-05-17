## Summary
- Remove Axiom's Hypridle 15 minute automatic suspend listener.
- Preserve the existing 5 minute lock and 10 minute DPMS off/on idle behavior.
- Record Legion validation and review evidence for the idle policy change.

## Validation
- `grep -E 'suspend_cmd|systemctl suspend|loginctl suspend|timeout = 900' config/hypr/hypridle.conf` returned no matches.
- `git diff --check`
- `DOTFILES_HOME="$PWD" nix build --impure "path:$PWD#nixosConfigurations.axiom.config.system.build.toplevel" --no-link`

## Notes
- Live Hypridle reload and real idle behavior should be smoke-tested after deployment on Axiom.
