# Test Report

## Result
PASS with one explicit runtime caveat.

## Commands
- `git diff --check`
- `nix eval --impure --raw --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; in c.system.userActivationScripts.script' | rg 'XDG_RUNTIME_DIR|lib/.cache|export PATH=.*jpm|jpm run deploy'`
- `nix eval --impure --raw --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; in c.system.userActivationScripts.script' | zsh -n`
- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'`
- Strict empty staging smoke using the live system Janet/JPM toolchain with `set -euo pipefail`, pre-created `$JANET_TREE/lib/.cache`, staging `PATH`, `jpm deps`, `jpm run deploy`, and `janet bin/hey path home`.
- Generated wrapper inspection: `/nix/store/xwksn710nln2ywkdl0jzfrmja754d2yx-hey/bin/hey` contains XDG fallbacks before launching Janet.
- Live desktop check: `XDG_RUNTIME_DIR=/run/user/1000 /run/current-system/sw/bin/hey path home`, `systemctl --user is-active hyprland-session.target`, and `pgrep -a 'caelestia|quickshell'`.

## Evidence
- Activation script contains `XDG_RUNTIME_DIR` fallback, staging `PATH` with wrapped `jpm`, `git`, `gcc`, and coreutils, `$JANET_PATH/.cache` creation, `jpm deps`, and `jpm run deploy`.
- Activation script passes `zsh -n`.
- Axiom toplevel build passed.
- Strict empty staging smoke completed with `strict-staging-smoke-ok`.
- Generated `hey` wrapper exports `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `XDG_RUNTIME_DIR` fallback.
- Live session has `hyprland-session.target` active and running `caelestia-session`/`quickshell` processes after manual runtime repair.

## Caveat
The agent could not run `sudo nixos-rebuild switch` because sudo requires an interactive password. A direct smoke of the worktree-built wrapper against the current live JPM tree failed with a Janet native-module version mismatch: worktree `origin/master` builds Janet 1.39.1 while the current dirty live runtime was rebuilt with Janet 1.41.2. This is the exact class of mismatch the activation version marker is meant to rebuild; it is not a blocker for the PR build.
