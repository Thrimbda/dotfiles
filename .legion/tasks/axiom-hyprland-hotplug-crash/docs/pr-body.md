## Summary

Guards Axiom's confirmed Hyprland v0.56.1 XWayland floating-map crash during transient monitor loss.

- Adds an Axiom-only patched Hyprland package override.
- Falls back to the cached floating work-area origin when the workspace monitor is absent.
- Keeps XWayland, fractional scaling, DP-4/DP-5 configuration, and monitor hotplug enabled.
- Adds a `0.56.1` assertion so future Hyprland updates require explicit patch review.

## Verification

- `patch --dry-run --verbose --fuzz=0 ...` passed.
- The patched Hyprland package built successfully.
- `nixos-rebuild build --flake .#axiom --show-trace -L` passed.
- Final debug-source overlay confirms the guard is present.
- `git diff --cached --check` passed.

## Risk and Rollback

The change only affects the monitor-less fallback branch; normal monitor-backed placement is unchanged. Remove `./modules/hyprland-hotplug-guard.nix` from `hosts/axiom/default.nix` to restore the shared unpatched package.

No live activation or hotplug test was performed. Deployment requires an explicit switch/restart decision, followed by a physical hotplug or DPMS smoke that checks for the fallback warning and absence of a Hyprland coredump.
