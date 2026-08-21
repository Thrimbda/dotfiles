## Summary

- Replace the monitor hotplug reconciler's Lua-incompatible `hyprctl keyword monitor` call with `hyprctl eval` and `hl.monitor`.
- Preserve the existing monitor matching, dynamic mode selection, position, and scale logic.
- Document the diagnosis, validation, review, rollback, and deferred live smoke test.

## Root Cause

The deployed Lua configuration rejects the legacy command. The responsible user service logged:

```text
keyword can't work with non-legacy parsers. Use eval.
```

## Validation

- `nix eval --raw --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- Representative generated `hl.monitor(...)` expression parsed by the Nix-evaluated `luac`.
- `nix build --no-link --print-out-paths --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel -L`
- Inspected the Nix-built reconciler helper: it emits `hl.monitor(...)` and invokes `hyprctl eval`; no legacy `keyword monitor` call remains.
- `git diff --check`

## Post-Deployment Smoke

After deployment, trigger a controlled monitor reconcile or power-cycle. Confirm the legacy-parser error does not recur, DP-4/DP-5 layout remains correct, and Hyprland does not crash.

## Rollback

Revert this change and deploy the prior Nix generation.
