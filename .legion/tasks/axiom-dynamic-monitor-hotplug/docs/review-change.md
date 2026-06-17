# Change Review

## Verdict

PASS.

## Findings

No blocking findings remain.

## Fixed During Review

- `modules/desktop/hyprland.nix`: the Caelestia per-monitor seed helper originally copied a temporary file into place and then cleared its EXIT trap without deleting the temporary file. This would have left `shell.json.XXXXXX` files behind when per-monitor settings are declared. The helper now removes the temporary file before clearing the trap.

## Scope Review

- In scope: cohesive monitor inventory, Axiom monitor policy, Hyprland startup/hotplug reconciliation, Caelestia per-monitor seed support, and Legion task evidence.
- Out of scope avoided: HDR changes, color-management mitigation changes, full cross-host display subsystem, and immutable ownership of user Caelestia global config.

## Security Lens

Applied because the change adds a session user service and processes live compositor metadata.

- The watcher only reads Hyprland event socket events and does not evaluate event payloads as shell.
- The reconciler passes generated monitor specs as a single `hyprctl` argument, avoiding shell command injection from monitor names.
- The service is scoped to `hyprland-session.target` and runs as the user, not as a privileged system service.

## Residual Risk

Hyprland/Aquamarine atomic modeset failures can still require a clean compositor restart. The change improves policy and normal hotplug behavior but does not claim to repair a compositor/driver bad state after repeated atomic commit failures.
