# Hey Activation Staging Environment

## Status
Implemented and verified in PR branch `legion/20260703-hey-activation-staging-env`.

## Summary
Axiom's Caelestia startup was still blocked by a broken `hey` runtime after the first safe-staging fix. The staged rebuild logic preserved the active tree, but the staging environment itself was incomplete: JPM's git cache parent directory was missing, nested `jpm deps` calls could not find `jpm` through `PATH`, and `hey` module loading failed in sparse activation shells without XDG runtime variables.

The fix keeps the staged replacement model and makes the rebuild environment self-contained enough for user activation: Linux `hey` calls get XDG fallbacks, activation creates `$JANET_TREE/lib/.cache`, and staged rebuilds prepend the required `jpm`, `git`, compiler, and coreutils paths.

## Durable Takeaway
When `hey` startup failures mention missing Janet modules or native ABI mismatch, repair the managed JPM runtime through the activation staging path. Do not add alternate Caelestia launchers. A valid staging environment must include cache directories, tool `PATH`, XDG fallbacks, and a final `hey path home` smoke before promoting the staged tree.

## Evidence
- Axiom toplevel build passed.
- Generated activation script contains XDG fallback, staging `PATH`, `$JANET_PATH/.cache` creation, `jpm deps`, and `jpm run deploy`.
- Strict empty staging smoke passed with the live system toolchain.
- Live session was repaired manually: `hyprland-session.target` active with `caelestia-session` and `quickshell` running.
