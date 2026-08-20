# axiom-hyprland-hotplug-crash

## Metadata

- `task-id`: `axiom-hyprland-hotplug-crash`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Four retained Axiom Hyprland 0.56.1 incidents share the XWayland floating-map path during temporary loss of both configured outputs.
- PR #180 merged Axiom's host-only package patch that uses the cached floating work-area origin when a workspace monitor is absent, rather than dereferencing it.
- The exact patched package and Axiom closure build successfully while retaining XWayland, DP-4/DP-5 scaling, and monitor hotplug.
- Source delivery is complete. No live deployment or physical output-loss smoke has run; that work remains a maintenance follow-up.

## Reusable Decisions

- Do not claim a Hyprland version-only upgrade fixes a crash unless the implicated source path contains the relevant guard.
- For a temporary missing-monitor state, preserve the existing work-area fallback instead of returning from target addition after the layout already retained the target.
- Use a host-only package override and exact-version assertion for a local upstream patch whose applicability must be re-reviewed on package drift.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-hyprland-hotplug-crash/plan.md`
- `log`: `.legion/tasks/axiom-hyprland-hotplug-crash/log.md`
- `tasks`: `.legion/tasks/axiom-hyprland-hotplug-crash/tasks.md`
- `rfc`: `.legion/tasks/axiom-hyprland-hotplug-crash/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-hyprland-hotplug-crash/docs/review-rfc.md`, `.legion/tasks/axiom-hyprland-hotplug-crash/docs/review-change.md`
- `report`: `.legion/tasks/axiom-hyprland-hotplug-crash/docs/report-walkthrough.md`
