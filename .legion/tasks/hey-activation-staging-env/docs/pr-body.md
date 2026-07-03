## Summary
- Harden `hey` activation staging with XDG fallbacks and required tool `PATH`.
- Pre-create the JPM staging cache directory before `jpm deps`.
- Route `heyBin` through the generated `hey` wrapper so non-graphical callers get the same XDG defaults.

## Verification
- `git diff --check`
- Activation script guard inspection and `zsh -n`
- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'`
- Strict empty staging JPM rebuild smoke
- Live `hey`/Caelestia state check after manual runtime repair

## Notes
- Could not run `sudo nixos-rebuild switch` from the agent because sudo requires an interactive password.
