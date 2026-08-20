# axiom-qwen38-q6-switcher

## Metadata

- `task-id`: `axiom-qwen38-q6-switcher`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task makes the standard Q6_K MTP artifact the default 128K Axiom Qwen model while keeping Q4 as an operator-selectable rollback. One service reads `active.gguf`; `qwen-model` provides fixed Q4/Q6 selection plus start, stop, restart, and status. Closure, ShellCheck, artifact integrity, and reviews pass; merged Q6 GPU fit and switching remain pending.

## Reusable Decisions

- Keep multiple large quantizations on disk but permit only one service/model to own VRAM and the API port.
- Restrict model-control commands to verified fixed targets and a fixed systemd unit; do not accept arbitrary paths through a sudo-adjacent wrapper.
- Preserve mutable operator selection across rebuilds while seeding the preferred default only when no selection exists.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-qwen38-q6-switcher/plan.md`
- `log`: `.legion/tasks/axiom-qwen38-q6-switcher/log.md`
- `tasks`: `.legion/tasks/axiom-qwen38-q6-switcher/tasks.md`
- `rfc`: `.legion/tasks/axiom-qwen38-q6-switcher/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-qwen38-q6-switcher/docs/review-rfc.md`, `.legion/tasks/axiom-qwen38-q6-switcher/docs/review-change.md`
- `verification`: `.legion/tasks/axiom-qwen38-q6-switcher/docs/test-report.md`
- `report`: `.legion/tasks/axiom-qwen38-q6-switcher/docs/report-walkthrough.md`
