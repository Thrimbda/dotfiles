# Walkthrough: Axiom Caelestia Keep Awake Path Fix

Mode: implementation

## Problem

After PR #48 deployed, Axiom did not show Keep Awake enabled by default. Runtime service inspection showed `axiom-caelestia-keep-awake.service` was installed and enabled, while `caelestia-shell.service` and `hyprland-session.target` were active. The oneshot itself failed with `FileNotFoundError: 'caelestia-shell'`.

## Cause

The helper invoked `${caelestia-cli}/bin/caelestia shell idleInhibitor enable`. The Python CLI then tries to run `caelestia-shell` by name. The generated oneshot unit has a minimal NixOS `PATH`, so that subprocess lookup failed before reaching Caelestia IPC.

## Change

- Updated `hosts/axiom/default.nix` so `axiom-caelestia-keep-awake` calls the evaluated Caelestia shell binary directly:

```sh
${caelestia-shell}/bin/caelestia-shell ipc call idleInhibitor enable
```

- Kept the existing retry loop and session target wiring.
- Kept Caelestia Keep Awake / `idleInhibitor` as the UI source of truth.

## Validation

- Runtime diagnosis captured the failed service and active shell/session state.
- Manual current-session direct IPC returned `true` after enabling Keep Awake.
- Targeted Nix assertions passed for service wiring, direct shell helper text, and absence of old custom sleep services/packages.
- `git diff --check` passed.
- Axiom toplevel build passed.

## Deployment Note

After deploying the generation, reset/restart the failed oneshot or start a fresh Hyprland session, then confirm `caelestia shell idleInhibitor isEnabled` reports enabled.
