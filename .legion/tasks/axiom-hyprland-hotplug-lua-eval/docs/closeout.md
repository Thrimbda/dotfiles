# Closeout: Lua Eval Monitor Reconciliation

## Source Delivery

- PR: #189, `fix(axiom): use Lua eval for monitor reconcile`
- Merge commit: `f0db40cf7aee4435345088f66279d71f0eb53459`
- Checks: GitHub reported no required checks.
- Review: `docs/review-change.md` passed with no blocking findings.

## Completed Scope

- Replaced the Lua-incompatible `hyprctl keyword monitor` runtime call with generated `hl.monitor(...)` submitted through `hyprctl eval`.
- Preserved monitor discovery, matching, mode selection, position, scale, the XWayland monitor-loss guard, keyboard/Fcitx configuration, and session lifecycle boundaries.
- Recorded Nix evaluation, Lua syntax, generated helper, and final rebased Axiom closure evidence.

## Deferred Deployment Evidence

PR #189 has not been activated from this task. After deployment, trigger a controlled monitor reconcile or monitor power-cycle and confirm:

1. `hyprland-monitor-hotplug.service` does not log `keyword can't work with non-legacy parsers. Use eval.`
2. DP-4 and DP-5 retain their configured mode, position, and scale.
3. Hyprland stays running without a crash or safe-mode recovery.

## Rollback

Revert the source change and deploy the prior Nix generation. No persistent state or migration is involved.
