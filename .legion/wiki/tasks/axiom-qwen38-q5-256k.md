# axiom-qwen38-q5-256k

## Metadata

- `task-id`: `axiom-qwen38-q5-256k`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `true`
- `supersedes`: `axiom-qwen38-q6-switcher`
- `superseded-by`: `axiom-qwen38-q4-256k-q6-profile`

## Outcome Summary

Historical snapshot: Q5_K_M temporarily provided 262144-token/Q8 context through llama.cpp `--fit`, but its CPU/GPU hybrid path was limited to about 30.4 tok/s. It was superseded by the verified Q4 full-GPU 256K profile; the Q5 command path and local artifact were removed.

## Reusable Decisions

- Validate a new GGUF with llama.cpp before activation even when its upstream SHA-256 matches.
- Profile GPU layer policy per quantization rather than assuming all long-context profiles need the same CPU/GPU split.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-qwen38-q5-256k/plan.md`
- `log`: `.legion/tasks/axiom-qwen38-q5-256k/log.md`
- `tasks`: `.legion/tasks/axiom-qwen38-q5-256k/tasks.md`
- `rfc`: `.legion/tasks/axiom-qwen38-q5-256k/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-qwen38-q5-256k/docs/review-rfc.md`, `.legion/tasks/axiom-qwen38-q5-256k/docs/review-change.md`
- `verification`: `.legion/tasks/axiom-qwen38-q5-256k/docs/test-report.md`
- `report`: `.legion/tasks/axiom-qwen38-q5-256k/docs/report-walkthrough.md`
