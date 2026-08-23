# axiom-qwen38-q6-switcher

## Metadata

- `task-id`: `axiom-qwen38-q6-switcher`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `true`
- `supersedes`: `(none)`
- `superseded-by`: `axiom-qwen38-q5-256k`

## Outcome Summary

Historical snapshot: the standard Q6_K MTP artifact was Axiom's default 128K Qwen model, with Q4 retained as an operator-selectable rollback. The fixed-target control and atomic selection model remain valid, but the default profile is superseded by Q5 256K in `axiom-qwen38-q5-256k`.

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
