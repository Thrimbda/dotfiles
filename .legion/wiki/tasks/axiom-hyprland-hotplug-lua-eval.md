# axiom-hyprland-hotplug-lua-eval

## Metadata

- `task-id`: `axiom-hyprland-hotplug-lua-eval`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- The Axiom monitor hotplug reconciler used `hyprctl keyword monitor` despite the repository's Lua-only Hyprland configuration.
- PR #189 replaced that rejected legacy parser call with a generated `hl.monitor(...)` expression executed through `hyprctl eval`.
- Existing monitor selection, output values, XWayland monitor-loss guard, keyboard/Fcitx configuration, and session lifecycle remain unchanged.
- Source and generated-helper validation passed, including a final rebased Axiom closure build. Deployment and physical hotplug proof remain maintenance follow-up work.

## Reusable Decisions

- Under Hyprland Lua configuration, use `hyprctl eval` with `hl.monitor({ ... })` for runtime monitor updates; do not use `hyprctl keyword monitor`.
- Serialize dynamic monitor strings through jq `@json`, keep scale numeric, and pass generated Lua as one argument without shell evaluation.
- Treat build/source validation and physical monitor hotplug validation as separate evidence classes.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-hyprland-hotplug-lua-eval/plan.md`
- `log`: `.legion/tasks/axiom-hyprland-hotplug-lua-eval/log.md`
- `tasks`: `.legion/tasks/axiom-hyprland-hotplug-lua-eval/tasks.md`
- `rfc`: `.legion/tasks/axiom-hyprland-hotplug-lua-eval/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-hyprland-hotplug-lua-eval/docs/review-change.md`
- `report`: `.legion/tasks/axiom-hyprland-hotplug-lua-eval/docs/report-walkthrough.md`
