# Walkthrough

## Summary
This change hardens Axiom's `hey` activation path so the staged JPM runtime rebuild can succeed from a sparse user activation environment.

## What Changed
- Added shared XDG fallback exports for Linux `hey` execution.
- Made the installed `hey` wrapper use those XDG fallbacks before launching Janet.
- Pointed `heyBin` at the wrapper so systemd/app hooks get the same runtime defaults.
- Made staged JPM rebuilds create `$JANET_TREE/lib/.cache` and prepend required tool paths for `jpm`, `git`, `gcc`, and coreutils.

## Verification
- `git diff --check`: pass.
- Activation script guard inspection: pass.
- Activation script `zsh -n`: pass.
- Axiom toplevel build: pass.
- Strict empty staging smoke: pass.
- Live `hey`/Caelestia state after runtime repair: pass.

## Caveat
Full `nixos-rebuild switch` was not run by the agent because sudo requires an interactive password.
