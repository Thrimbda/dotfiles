# Change Review: Lua Eval Monitor Reconciliation

## Verdict

PASS

## Blocking Findings

None.

## Correctness Review

- `modules/desktop/hyprland.nix:146` changes only the final representation emitted after the existing monitor matching, mode selection, and `needsApply` checks. Output, mode, position, and scale remain the same inputs to the runtime operation.
- `modules/desktop/hyprland.nix:157` passes the generated Lua statement as one quoted argument to `hyprctl eval`, the documented runtime mechanism for Lua configuration.
- The Nix-built helper at `/nix/store/ihhzcdm6xxq4n2rbsx93b1y4lwmzqk10-hyprland-reconcile-monitors/bin/hyprland-reconcile-monitors` contains the expected `hl.monitor(...)` generation and `eval` invocation, confirming the source survives Nix rendering unchanged.

## Scope Review

The only production source change is the two-line monitor reconciler compatibility fix. No package patch, keyboard/Fcitx configuration, monitor inventory, or session lifecycle code changed. Task documentation is within the approved task directory.

## Safety Review

No authentication, secret, permission, or external trust-boundary change is present. A focused input-safety check was applied because runtime Lua is evaluated:

- Connector names, modes, and configured positions are serialized through jq `@json`, preventing quotation from changing the generated Lua structure.
- Modes continue to pass the existing numeric mode parser; scale is converted to a jq number.
- The shell passes the resulting text as one argument and does not shell-evaluate it.

## Verification Review

The verification report records successful Nix evaluation, generated-expression Lua parsing, full Axiom closure build, built-helper inspection, and whitespace validation. A physical monitor power-cycle is correctly deferred because this worktree must not activate or disturb the current graphical session.

## Residual Risk

The post-deployment monitor reconcile/hotplug smoke test remains required to verify the runtime timing path on real DP-4/DP-5 hardware. This is a known validation boundary, not a source-delivery blocker.
