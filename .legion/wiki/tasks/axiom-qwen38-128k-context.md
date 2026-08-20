# axiom-qwen38-128k-context

## Metadata

- `task-id`: `axiom-qwen38-128k-context`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task raises Axiom's deployed local Qwen context from 64K to 128K while retaining the existing one-slot CUDA, Q4 KV, flash-attention, and MTP configuration. The GGUF reports a native 256K training context, so 128K requires no RoPE override. The complete Axiom closure builds; merged runtime capacity and OpenCode alignment remain pending.

## Reusable Decisions

- Keep the server and OpenCode context declarations identical so client compaction reflects the effective slot size.
- Prefer 128K over the model-native 256K on the 32GB RTX 5090 because KV memory scales linearly with context.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-qwen38-128k-context/plan.md`
- `log`: `.legion/tasks/axiom-qwen38-128k-context/log.md`
- `tasks`: `.legion/tasks/axiom-qwen38-128k-context/tasks.md`
- `verification`: `.legion/tasks/axiom-qwen38-128k-context/docs/test-report.md`
- `review`: `.legion/tasks/axiom-qwen38-128k-context/docs/review-change.md`
- `report`: `.legion/tasks/axiom-qwen38-128k-context/docs/report-walkthrough.md`
