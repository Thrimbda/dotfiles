# Hey JPM Activation Safe Rebuild

## Metadata

- `task-id`: `hey-jpm-activation-safe-rebuild`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- `hey` activation no longer deletes the active JPM runtime before attempting network-backed dependency rebuilds.
- Rebuilds are gated by Janet version changes, `project.janet` hash changes, or a failed active-runtime smoke.
- Rebuilds occur in a staging JPM tree and are promoted only after `hey path home` succeeds under the staged dependencies.
- If staging rebuild fails and the old runtime still works, activation keeps the old tree; if no usable runtime remains, activation fails explicitly.

## Reusable Decisions

- Desktop-critical `hey hook startup` must not depend on destructive in-place JPM rebuilds.
- Mutable JPM artifacts should be staged and smoke-tested before replacing active runtime state.
- Native `c1ctl hook` remains a future migration slice, not part of this fix.

## Related Raw Sources

- `plan`: `.legion/tasks/hey-jpm-activation-safe-rebuild/plan.md`
- `log`: `.legion/tasks/hey-jpm-activation-safe-rebuild/log.md`
- `tasks`: `.legion/tasks/hey-jpm-activation-safe-rebuild/tasks.md`
- `test-report`: `.legion/tasks/hey-jpm-activation-safe-rebuild/docs/test-report.md`
- `review-change`: `.legion/tasks/hey-jpm-activation-safe-rebuild/docs/review-change.md`
- `report`: `.legion/tasks/hey-jpm-activation-safe-rebuild/docs/report-walkthrough.md`
