# Axiom Second Monitor Workspaces

## Goal

Make Axiom's second monitor usable from keyboard shortcuts without breaking the existing primary-monitor `SUPER+1..0` workflow.

## Problem

Axiom currently binds workspaces 1 through 10 to the primary monitor. Hyprland can create and show workspace 11 on the second monitor, but the generated shortcut set only covers workspaces 1 through 10, so windows cannot be opened or moved to the second monitor through the normal numeric shortcuts.

## Acceptance

- Existing `SUPER+1..0` workspace switching remains unchanged for workspaces 1 through 10.
- Existing `SUPER+SHIFT+1..0` window moves remain unchanged for workspaces 1 through 10.
- New second-monitor shortcuts are checked for conflicts before implementation.
- New `SUPER+ALT+1..0` shortcuts focus second-monitor workspaces 11 through 20.
- New `SUPER+ALT+SHIFT+1..0` shortcuts move the active window to second-monitor workspaces 11 through 20.
- Generated workspace config binds workspaces 11 through 20 to the configured secondary monitor when one is known.
- The shortcut reference text documents the new second-monitor workspace bindings.

## Scope

- Update generated Hyprland workspace/keybind configuration in the existing desktop module.
- Use the existing Axiom monitor inventory to identify primary and secondary monitors.
- Keep this scoped to workspace/keybind behavior, not monitor mode/hotplug policy.

## Non-Goals

- Do not redesign all workspace numbering.
- Do not replace Caelestia workspace UI behavior.
- Do not add mouse/display management UI.
- Do not change application placement rules except where generated workspace bindings naturally affect monitor selection.

## Assumptions

- `DP-4` remains Axiom's primary monitor and `DP-5` remains the preferred secondary monitor under the current inventory.
- `SUPER+ALT+number` and `SUPER+ALT+SHIFT+number` are available unless repository conflict checks prove otherwise.
- Binding workspaces 11 through 20 to the secondary monitor is enough for opening windows there after focusing the corresponding workspace.

## Constraints

- Preserve the current 1 through 10 shortcuts exactly.
- Avoid ambiguous or hidden keybinding collisions in generated Hyprland config.
- Generated config must remain Hyprland 0.53-compatible.

## Risks

- Caelestia's workspace display may not visibly show workspaces 11 through 20 if upstream bar settings limit the visible workspace count; the keybind behavior should still work.
- If the secondary monitor is absent, workspaces 11 through 20 should not break session startup.

## Recommended Direction

Use a simple primary/secondary split: keep workspaces 1 through 10 on the primary monitor and add workspaces 11 through 20 on the first non-primary configured monitor. Generate secondary numeric bindings using `SUPER+ALT` and `SUPER+ALT+SHIFT` so the existing primary bindings stay stable.

## Phases

- Brainstorm: create this task contract.
- Implementation: inspect generated keybinds for conflicts, implement the secondary workspace bindings, and update docs/reference text.
- Verification: evaluate generated keybind/workspace config and run static checks.
- Review and delivery: review readiness, create walkthrough/PR body, write wiki summary, and deliver through PR.
