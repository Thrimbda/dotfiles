# Delivery Walkthrough: Lua Eval Monitor Reconciliation

## Mode

Implementation

## Problem Addressed

The Axiom monitor hotplug reconciler issued `hyprctl keyword monitor` even though the active Hyprland configuration is Lua-based. The service journal records Hyprland rejecting that command with `keyword can't work with non-legacy parsers. Use eval.`

## Delivered Change

- Preserve all existing monitor discovery, identity matching, mode selection, position, scale, and change-detection logic.
- Serialize the selected values into `hl.monitor({ ... })` using jq JSON string literals and a numeric scale.
- Submit the Lua statement through `hyprctl eval` instead of the legacy `keyword monitor` interface.

## Evidence

- Design: `docs/rfc.md` selects the narrow Lua-eval path and documents rollback.
- Verification: `docs/test-report.md` records successful Nix evaluation, generated-expression Lua parsing, full Axiom closure build, and inspection of the Nix-built helper.
- Review: `docs/review-change.md` is PASS with no blocking findings; it confirms the dynamic values are safely serialized and scope stayed bounded.

## Delivery Status

Source delivery merged through PR #189 at `f0db40cf7aee4435345088f66279d71f0eb53459`. GitHub reported no required checks for the branch. This task did not activate the resulting NixOS generation.

## Scope Boundaries

- The existing Axiom-only XWayland monitor-loss package guard is unchanged.
- Colemak and Fcitx are unchanged; the physical keyboard test produced `arst` during diagnosis.
- Monitor inventory, UWSM/systemd session-target behavior, and live-session activation are out of scope.

## Remaining Runtime Check

After merge and deployment, trigger a controlled monitor reconcile or power-cycle and confirm:

1. `hyprland-monitor-hotplug.service` no longer logs the legacy-parser error.
2. DP-4 and DP-5 retain their configured mode, position, and scale.
3. Hyprland remains running without a new crash or safe-mode recovery.

## Rollback

Revert the helper change and deploy the prior Nix generation. The change has no persistent state or data migration.
