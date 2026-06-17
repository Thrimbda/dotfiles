# Axiom Dynamic Monitor Hotplug

## Goal

Make Axiom display handling dynamic and cohesive: a single Nix-owned monitor inventory should drive Hyprland startup rules, hotplug/runtime mode selection, and Caelestia per-monitor configuration.

## Problem

Axiom currently hard-codes Hyprland monitor rules by output name. That avoids the previous unsafe wildcard rule, but it does not express the desired policy: when a display is plugged in, keep its native/highest resolution and use the highest refresh rate available at that resolution. The current approach also leaves Caelestia monitor-specific settings outside the same source of truth, so future monitor changes can drift between Hyprland and Caelestia.

## Acceptance

- A single high-cohesion Axiom monitor configuration defines known monitor identity, layout preference, scale, optional Caelestia per-monitor settings, and refresh policy.
- Generated Hyprland startup config no longer relies on a broad wildcard rule that can force 240Hz onto unrelated outputs.
- A generated hotplug/reconcile helper can inspect live Hyprland monitor modes and apply native-resolution/highest-refresh mode selection for connected outputs.
- A 4K240 display connected as the known OLED is configured at 4K240; a 4K120 display uses 4K120 rather than dropping resolution for a higher lower-resolution mode.
- Caelestia global and per-monitor configuration remains repository-seeded but mutable where existing design requires it, using upstream-supported `~/.config/caelestia/monitors/<screen-name>/shell.json` files.
- Verification covers Nix evaluation of generated Hyprland and Caelestia files plus static checks for the generated helper script.

## Scope

- Refactor Axiom monitor facts into one host-local configuration shape.
- Extend the shared Hyprland/Caelestia modules only as needed to consume that cohesive shape.
- Add or generate a runtime monitor reconcile path for startup/reload/hotplug use.
- Preserve the current Axiom Caelestia session runner ownership model and mutable `shell.json` behavior.

## Non-Goals

- Do not enable HDR or remove the current `render.cm_enabled = false` mitigation.
- Do not introduce a broad cross-host display daemon unless the Axiom implementation proves reusable later.
- Do not manage every upstream Caelestia setting declaratively.
- Do not choose lower resolution solely to reach a higher refresh rate.
- Do not require physical hotplug testing to merge; live smoke remains a post-deploy follow-up.

## Assumptions

- Hyprland `monitors all -j` exposes enough live mode data to choose the preferred/native resolution and the highest refresh at that resolution.
- Output names such as `DP-4` and `DP-5` are useful runtime handles but should not be the only stable identity where model/serial data is available.
- Caelestia per-monitor overrides are keyed by screen/output name, per upstream documentation.
- The repo should seed Caelestia per-monitor files only when the monitor inventory declares them, and should preserve user-owned global shell state.

## Constraints

- The design must keep monitor-related host policy high-cohesion and avoid scattering display facts across unrelated host snippets, generated config, and ad-hoc scripts.
- Runtime commands must run inside the Hyprland/UWSM session and must not rely on an interactive shell PATH.
- Existing non-Axiom hosts should not change behavior unless they opt into the new shape.
- Generated config must remain compatible with Hyprland 0.53 syntax.

## Risks

- Hyprland/Aquamarine/NVIDIA atomic modeset failures can still leave a live session in a bad state after DPMS or physical hotplug; the helper can reduce bad rules but cannot fix driver/compositor bugs.
- Matching monitors by output name alone can break when ports change; matching by description/model/serial needs careful fallback behavior.
- Caelestia per-monitor config files are keyed by screen name, so runtime output renames may need regeneration or conservative defaults.
- Applying monitor changes repeatedly can cause flicker or worsen a broken modeset state if not made idempotent.

## Recommended Direction

Create a single Axiom monitor inventory that contains known display entries and policy fields. Generate Hyprland static rules, a runtime reconcile helper, and optional Caelestia per-monitor seed files from that inventory.

Runtime mode selection should use this order:

1. Identify a connected output against known monitor facts where possible.
2. Determine the native/preferred resolution from live modes.
3. Select the highest refresh available at that resolution.
4. Apply the configured layout/scale and selected mode with `hyprctl keyword monitor`.
5. Leave unknown outputs on safe preferred/auto behavior unless the policy explicitly opts them into dynamic handling.

This keeps the repository source of truth cohesive while still allowing hotplug behavior to adapt to real EDID capabilities.

## Phases

- Brainstorm: create this task contract and checklist.
- Design: write and review an RFC for the cohesive monitor inventory, hotplug algorithm, and Caelestia config ownership.
- Implementation: implement the approved shape in an isolated worktree.
- Verification: evaluate generated config and run static/runtime-safe script checks.
- Review and delivery: readiness review, walkthrough, and wiki writeback.
