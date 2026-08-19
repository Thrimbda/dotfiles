# Change Review: Axiom Single Idle Owner And Hotplug Recovery

## Decision

PASS

## Blocking Findings

None.

## Correctness And Scope Review

- `hosts/axiom/default.nix` changes only the new Axiom-local `hypridle.enable` switch. Caelestia's existing 900-second lock and 1800-second DPMS policy remains intact.
- `modules/desktop/hyprland.nix` defaults the new switch to enabled, and static evaluation confirms Ramen still receives its Hypridle unit. The behavior change is therefore constrained to Axiom.
- The watcher no longer relies on the startup-time `HYPRLAND_INSTANCE_SIGNATURE`. It discovers a live instance through `hyprctl instances -j`, verifies socket2, prefers the matching Wayland socket, and falls back to the newest live instance when that environment value is stale.
- `pipefail` makes a refused `socat` connection observable to the loop. Both a failed connection and a clean event-stream end take the same unconditional two-second rediscovery delay, preventing the previously observed stale-socket retry storm.
- The test report directly evaluates all acceptance-relevant generated values, realizes the changed script, and checks its Bash syntax. `git diff --check` also passed.

## Security Review

No security trigger applies. The change neither crosses a trust boundary nor changes authentication, authorization, secrets, network exposure, or user-controlled privileged execution. The watcher only consumes local Hyprland JSON and uses the selected socket in a quoted command argument.

## Remaining Operational Evidence

Before judging the incident resolved, deployment must stop any already-running Hypridle process and exercise one full 30-minute DPMS/wake cycle. A repeat Hyprland coredump is an upstream-residual escalation signal, not a reason to silently reintroduce dual idle ownership.
