# RFC: Axiom Single Idle Owner And Hotplug Recovery

## Context

Axiom currently has two automatic idle control paths with the same policy:

- `config/hypr/hypridle.conf` starts a 900-second Caelestia lock action and an 1800-second legacy `hyprctl dispatch dpms ...` action.
- `hosts/axiom/default.nix` writes Caelestia `general.idle` settings with the same 900-second lock and 1800-second DPMS actions.

The Caelestia implementation already translates its DPMS actions to the current Lua dispatcher form. Hypridle logs prove that its legacy dispatcher command fails parsing. Making that command valid while retaining the Caelestia timer would create two effective DPMS changes at the same idle boundary.

The 2026-08-18 and 2026-08-19 coredumps show the same Hyprland 0.56.1 path: an XWayland surface maps through `CDefaultFloatingAlgorithm::newTarget` while the crash report records DRM connector scanning with all CRTCs unassigned. Hypridle disconnects only after the compositor crash. RustDesk and Zen failures also occur after the compositor exits, so they are not established as the initiating process.

The proposed 0.56.2 upgrade was rejected during research: the relevant floating-layout source is identical in 0.56.1 and 0.56.2. It would increase deployment surface without evidence that it fixes this failure.

Separately, `hyprland-monitor-hotplug` captures `HYPRLAND_INSTANCE_SIGNATURE` once. When Hyprland restarts, its old socket refuses connections and the script repeatedly invokes `socat` against that stale path. This does not explain the first crash, but it makes recovery noisy and leaves monitor reconciliation disconnected from the new compositor.

## Goals

- Retain Axiom's automatic 15-minute lock and 30-minute DPMS behavior.
- Give those automatic actions one owner: Caelestia.
- Keep Caelestia WlSessionLock, RustDesk, XWayland, and no-sleep policy unchanged.
- Make monitor hotplug reconciliation follow the active compositor socket and retry at a bounded rate after a disconnect.
- Preserve enough runtime observability to decide whether the residual Hyprland crash still occurs after the interaction surface is reduced.

## Non-Goals

- Do not claim to fix the unverified upstream XWayland/DRM crash.
- Do not disable automatic DPMS as a permanent workaround.
- Do not update all of `nixpkgs-unstable`, pin an unsupported Hyprland release, or maintain a local compositor patch.
- Do not change RustDesk's service contract or Caelestia's lock UI.

## Options

### 1. Caelestia as the sole idle owner

Disable the Axiom Hypridle user service while retaining the existing Caelestia idle settings. Add a narrow module option so other hosts keep their current Hypridle service by default. Make the monitor watcher discover the live instance through `hyprctl instances -j`, reconnect after a bounded delay, and avoid treating a dead socket as a successful stream.

Benefits:

- Keeps the selected Caelestia WlSessionLock and its current Lua DPMS implementation.
- Removes duplicate lock and DPMS callbacks without removing automatic DPMS.
- Removes Hypridle's known abort after a compositor disconnect from the recovery path.
- Limits the behavioral change to Axiom.

Costs and risks:

- Caelestia becomes the sole automatic idle dependency for this host.
- The compositor can still hit the unresolved upstream crash; live evidence remains necessary.

### 2. Hypridle as the sole idle owner

Remove Caelestia's idle timeouts, update Hypridle to the Lua dispatcher syntax, and retain Caelestia only as the lock IPC client.

Benefits:

- Uses the dedicated Hyprland idle daemon.

Costs and risks:

- Reverses the active Caelestia idle integration and mutable config migration.
- Reintroduces an idle path already shown to abort after a compositor disconnect.
- Requires more migration and rollback handling for no demonstrated benefit.

### 3. Keep both owners and only add logging or upgrade Hyprland

Leave the dual timeouts in place and either instrument them or move to 0.56.2.

Benefits:

- Smallest immediate configuration change.

Costs and risks:

- Preserves the concurrent transition surface.
- The version change is not supported by a relevant source diff.
- Logging alone does not improve the next overnight recovery.

## Decision

Choose option 1.

Add a Hypridle-service enable switch to the shared desktop module, defaulting to enabled. Set it off only on Axiom, where Caelestia's existing configuration remains the authoritative idle policy. Do not change the global checked-in `hypridle.conf`, so hosts that rely on Hypridle retain their current behavior.

Rework the monitor watcher to obtain the current live Hyprland instance before opening socket2. If its stream ends or connection fails, it must wait before rediscovering the instance. The watcher must not invoke reconciliation while there is no live compositor socket. This fixes the stale-signature recovery defect without claiming it prevents the original compositor coredump.

## Scope

- `modules/desktop/hyprland.nix`: Axiom-selectable Hypridle service gate and resilient monitor watcher.
- `hosts/axiom/default.nix`: disable only the Hypridle service on Axiom.
- `.legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/**`: evidence and delivery records.
- `.legion/wiki/**`: durable current behavior and the unresolved upstream residual.

## Verification

- Evaluate Axiom's generated configuration to prove the Hypridle user unit is absent or disabled, while Caelestia still has exactly the 900/1800 lock/DPMS policy and no sleep action.
- Inspect the generated watcher script for `hyprctl instances -j`, a live socket check, pipe-failure handling, and a bounded reconnect wait.
- Run formatting/static checks and evaluate the Axiom configuration.
- After deployment, stop any pre-existing Hypridle user process, then confirm Caelestia's idle settings and monitor watcher state in the live session.
- Leave the machine through one full 30-minute DPMS interval and wake it. Capture `journalctl`, `coredumpctl`, and the Hyprland crash report if the residual failure repeats.

## Rollback

Set the Axiom Hypridle enable switch back to true and rebuild to restore the previous dual-owner configuration. The watcher change is independently reversible by reverting its script change. No persistent schema, credential, or user-data migration is involved.

## Residual And Escalation

The root cause of the Hyprland coredump remains unproven. If it recurs after a single-owner DPMS cycle, preserve the new crash report, the preceding socket2 monitor events, and the current `hyprctl instances -j` output. Escalate upstream with the repeated XWayland/DRM backtrace rather than adding a speculative local compositor patch.
