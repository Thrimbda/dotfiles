## Summary

- Make Caelestia the only automatic idle owner on Axiom while retaining the existing 15-minute lock and 30-minute DPMS policy.
- Stop generating Axiom's duplicate Hypridle user unit; other hosts retain the default enabled unit.
- Make the monitor hotplug watcher rediscover the current Hyprland socket and back off after every event-stream completion instead of hammering a stale signature.

## Validation

- `nix eval --impure --json --expr ...` verifies Axiom has no Hypridle unit, preserves Caelestia's 900/1800 policy without sleep, and leaves Ramen's default Hypridle unit enabled.
- Realized generated watcher script passes `bash -n`.
- Live `hyprctl instances -j` selection returns the active instance.
- `git diff --check` passes.

## Follow-Up

- After deployment, stop any already-running `hypridle.service` and run one full 30-minute DPMS/wake smoke test.
- The upstream Hyprland XWayland/DRM coredump remains an explicit residual; capture a fresh crash report and watcher journal if it repeats.
