# Change Review: Axiom Hyprland Hotplug XWayland Crash Fix

**Result:** PASS
**Reviewed:** 2026-08-20

## Findings

No blocking, major, or minor findings.

## Correctness

- The final build overlay replaces the unsafe workspace-monitor dereference with a locked monitor reference and `WORK_AREA.pos()` fallback.
- `CSpace` retains the last valid work area during monitor loss, and later workspace restoration rehomes mapped targets.
- The final package and closure were rebuilt after source-overlay inspection rejected earlier incomplete patch variants.

## Scope and Rollback

- Only Axiom imports the guard module; shared Hyprland configuration, XWayland settings, monitors, portal package, and hotplug policy remain unchanged.
- The override appends its patch rather than replacing any upstream patch list.
- The `0.56.1` assertion requires explicit review on future Hyprland input drift.
- Removing the Axiom module import restores the normal shared package selection.

## Security

No security trigger applies. The change does not alter credentials, permissions, network behavior, or trust boundaries.

## Remaining Validation Limit

Static and build evidence prove the known dereference is guarded. A separately authorized physical hotplug/DPMS smoke remains necessary to validate timing behavior in a live graphical session.
