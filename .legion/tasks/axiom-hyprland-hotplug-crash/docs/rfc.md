# RFC: Guard Floating XWayland Placement During Monitor Loss

**Status:** Implemented and merged in PR #180
**Risk:** Medium

## Context

When both Axiom outputs temporarily disappear, a workspace can have no associated monitor. If an XWayland window maps as floating in that interval, Hyprland 0.56.1 dereferences the missing monitor in `CDefaultFloatingAlgorithm::newTarget` and terminates the compositor. The failure recurred four times with the same stack.

The current `CSpace` code already preserves its last valid work area when its workspace has no monitor. The floating algorithm bypasses that protection by independently dereferencing the monitor only to obtain a placement origin for static position rules.

## Goals

- Prevent the proven null-monitor dereference in the floating XWayland map path.
- Preserve XWayland, fractional scaling, configured DP-4/DP-5 behavior, and the monitor-hotplug reconciler.
- Keep the mitigation Axiom-specific, minimal, reviewable, and trivial to revert.
- Leave a runtime log signal when fallback placement is used.

## Non-goals

- Identify the unnamed triggering X11 client or the physical cause of connector loss.
- Fix unrelated safe-mode teardown, historical color-management, NVIDIA VRAM, or client teardown failures.
- Change flake inputs, globally upgrade Hyprland, or backport unrelated upstream placement features.
- Run a live restart, DPMS, hotplug, or deployment test during this task.

## Options

### Disable XWayland, force-zero-scaling, or monitor hotplug

Rejected. These remove required desktop behavior without proving that the invalid state is avoided, and they do not repair the compositor dereference.

### Upgrade Hyprland

Rejected. Upstream research found no released or mainline guard for the implicated access. v0.56.2 and current main retain the dereference.

### Return early from `newTarget` when no monitor exists

Rejected. `CAlgorithm::addTarget` has already retained the target. An early return can leave the newly mapped window without a reliable geometry or later placement event.

### Use the last valid work-area origin during the transient monitor-less interval

Selected. Resolve the workspace monitor into a strong reference. When unavailable, use the `CSpace` floating work-area position already retained from the last valid output, log a warning, and continue the existing placement flow. This changes only the invalid-state branch; normal monitor-backed placement is unchanged.

## Decision

Add an Axiom-only `programs.hyprland.package` override with `lib.mkForce`. The override appends one source patch to `pkgs.unstable.hyprland`.

The host module asserts that the selected upstream package remains version `0.56.1`. A future unstable-input update must therefore explicitly re-evaluate or remove this local guard instead of silently applying it to changed upstream code.

The patch changes `CDefaultFloatingAlgorithm::newTarget` to:

1. Lock the target workspace monitor before reading its logical box.
2. Use its logical-box position when present, preserving normal behavior.
3. Use `workArea(true).pos()` and emit a warning when absent, preserving a valid placement origin until Hyprland restores the workspace's monitor association.

The portal package remains the existing `pkgs.unstable.xdg-desktop-portal-hyprland`; no config feature is disabled.

## Scope

- `hosts/axiom/default.nix`: import the host-specific package override.
- `hosts/axiom/modules/hyprland-hotplug-guard.nix`: append the patch to the Axiom compositor package.
- `hosts/axiom/modules/hyprland-xwayland-floating-monitor-guard.patch`: narrowly guard the known dereference.
- Task evidence and delivery documents.

## Verification

- Confirm the patch applies to the evaluated Hyprland 0.56.1 source and the selected package differs from the unpatched derivation.
- Build the Axiom Hyprland package and the Axiom NixOS closure with `nixos-rebuild build --flake .#axiom --show-trace -L`.
- Evaluate the generated Axiom configuration and inspect the selected package, retained XWayland enablement, monitor definitions, and hotplug service.
- Review the final diff for host-only scope and ensure no live session command was executed.
- Record that a future authorized live hotplug/DPMS smoke must look for the new fallback warning and absence of a Hyprland coredump.

## Rollback

Remove the Axiom guard-module import. This restores the original `pkgs.unstable.hyprland` selection without changing package inputs, state, monitor policy, or user data. If build or review exposes an issue, revert the three implementation files rather than disabling XWayland or monitor hotplug.
