# Delivery Walkthrough: Axiom Single Idle Owner And Hotplug Recovery

## Mode

Implementation

## User-Facing Outcome

Axiom keeps its 15-minute automatic lock and 30-minute automatic DPMS behavior, but Caelestia is now the sole automatic idle owner. This removes Hypridle's duplicate callbacks and its known crash-on-disconnect path from the overnight flow.

The monitor hotplug watcher now discovers the active Hyprland instance instead of retaining a dead socket signature after a compositor restart. It waits two seconds after every socket event stream ends before rediscovering the instance.

## Why This Change

Runtime evidence showed that the reported lock-client failure follows a Hyprland coredump, not an isolated lock command failure. The coredump path maps an XWayland surface while DRM CRTCs are unassigned. The repository also configured Hypridle and Caelestia to perform the same lock and DPMS actions at the same thresholds.

The initially considered Hyprland 0.56.2 upgrade was not used: research showed the relevant floating-layout source is unchanged from 0.56.1, so that upgrade would not be evidence-backed.

See `docs/rfc.md` for the complete evidence and alternatives.

## Changes

- `modules/desktop/hyprland.nix`
  - Adds `modules.desktop.hyprland.hypridle.enable`, defaulting to true for existing hosts.
  - Emits the Hypridle user unit only when enabled.
  - Rewrites the monitor watcher to select a current instance from `hyprctl instances -j`, validate socket2, use `pipefail`, and back off after every event-stream completion.
- `hosts/axiom/default.nix`
  - Sets `hypridle.enable = false`; Caelestia retains the existing 900-second lock and 1800-second DPMS settings.

## Validation

`docs/test-report.md` records:

- Rendered Axiom configuration has Hypridle disabled and no Hypridle user unit.
- Rendered Caelestia settings still provide exactly the 900-second lock and 1800-second DPMS actions with no sleep action.
- Ramen retains the default enabled Hypridle unit.
- The generated watcher script builds and passes `bash -n`.
- Its live instance-selection expression returns Axiom's active Hyprland instance without dispatching a compositor command.
- `git diff --check` passes.

`docs/review-change.md` records a PASS with no blocking correctness, scope, or security finding.

## Deployment And Follow-Up

After deployment, run `systemctl --user stop hypridle.service || true` to remove any pre-existing daemon from the current session. Confirm the watcher is active, then leave Axiom through a full 30-minute DPMS interval and wake it.

This change reduces a documented interaction and repairs crash recovery. It does not claim that the unresolved upstream Hyprland XWayland/DRM coredump is impossible. If it repeats, preserve the new crash report, watcher journal, and `hyprctl instances -j` output for upstream escalation.

## Rollback

Set `modules.desktop.hyprland.hypridle.enable = true` for Axiom and rebuild. The watcher behavior can be independently reverted with the same change set.
