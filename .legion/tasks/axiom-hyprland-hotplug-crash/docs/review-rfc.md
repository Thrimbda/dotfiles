# RFC Review: Guard Floating XWayland Placement During Monitor Loss

**Result:** PASS
**Reviewed:** 2026-08-20

## Blocking Findings

None.

## Evidence

- `CSpace` preserves its cached work area when its workspace monitor is absent (`src/layout/space/Space.cpp:77-110`).
- The implicated dereference is in `CDefaultFloatingAlgorithm::newTarget` before placement handling (`src/layout/algorithm/floating/default/DefaultFloatingAlgorithm.cpp:19-23`).
- Floating target position updates do not dereference the workspace monitor (`src/layout/target/WindowTarget.cpp:50-78`), and workspace restoration rehomes mapped targets when a monitor becomes available (`src/state/WorkspacePlacementController.cpp:294-322`).
- The Axiom-only package override is scoped, reversible, and paired with a static/build validation plan. The unknown client and physical hotplug cause are not claimed as resolved.

## Non-blocking Improvement Accepted

The implementation will assert the patched upstream package remains `0.56.1`. This turns future unstable-input drift into an explicit evaluation failure requiring review rather than silently retaining the local patch.
