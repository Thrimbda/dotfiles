# Design-lite: Lua-Compatible Monitor Reconciliation

## Context

Axiom loads Hyprland through `hyprland.lua`. The monitor hotplug reconciler in `modules/desktop/hyprland.nix` still applies runtime changes through `hyprctl keyword monitor`, which is a legacy-parser command. The user service journal records the resulting error:

```text
keyword can't work with non-legacy parsers. Use eval.
```

The user reported a red Hyprland overlay after display power cycling. The exact overlay text was not captured, but this is a direct, reproducible configuration compatibility error from the responsible service. Current `hyprctl configerrors` is empty, and the physical keyboard test outputs `arst`; keyboard configuration is not in scope.

## Options

### 1. Keep `hyprctl keyword monitor`

This preserves the current helper text but leaves monitor reconciliation rejected whenever it runs under Lua configuration. Rejected.

### 2. Generate `hl.monitor` and execute it with `hyprctl eval`

Keep the existing monitor discovery, matching, mode selection, and change detection. Change only the emitted command from a legacy comma-separated value to a Lua call:

```lua
hl.monitor({ output = "DP-4", mode = "3840x2160@240", position = "0x0", scale = 1.5 })
```

Pass that string as one argument to `hyprctl eval`. This is the documented runtime mechanism for a Lua configuration and applies the same monitor fields as the existing command. Selected.

### 3. Reintroduce legacy Hyprland configuration

Changing the entire configuration parser to retain `keyword` would affect all generated Lua configuration and is unrelated to the local service bug. Rejected.

## Decision

Update the jq program to emit a Lua `hl.monitor` expression. Connector names, parsed modes, and configured positions are serialized as JSON string literals; for the constrained values already accepted by the existing monitor logic, these are valid Lua string literals. Scale remains numeric. The shell passes the result directly to `hyprctl eval` without shell evaluation.

The service retains its existing retry and error-propagation behavior. The existing package-level XWayland monitor-loss guard, monitor inventory, Colemak configuration, Fcitx profile, and session-target behavior are explicitly out of scope.

## Verification

- Inspect the generated helper to ensure it no longer calls `hyprctl keyword monitor` and does call `hyprctl eval`.
- Exercise the jq command-generation path with representative Axiom monitor data and confirm the emitted Lua syntax and values.
- Build the affected Axiom configuration without activation.
- Review the diff for scope boundaries and preserve a post-deployment physical monitor power-cycle smoke test.

## Rollback

Revert the single helper change and rebuild/redeploy the prior Nix generation. No persisted monitor state or data migration is involved.
