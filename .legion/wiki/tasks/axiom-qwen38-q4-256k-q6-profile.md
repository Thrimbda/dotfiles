# axiom-qwen38-q4-256k-q6-profile

## Metadata

- `task-id`: `axiom-qwen38-q4-256k-q6-profile`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-qwen38-q5-256k`
- `superseded-by`: `(none)`

## Outcome Summary

Axiom now defaults to the RVN Q4_K_M MTP model at 262144 tokens with Q8 KV cache and full GPU offload. The live one-slot profile reaches 107.91 tok/s with 96-97% GPU SM use and about one CPU core.

Q6_K remains an operator-selectable high-precision 131072-token/Q4 cache profile. Q5 configuration, selection, launcher support, and the local model artifact were removed after Q4/Q6 runtime validation.

## Reusable Decisions

- Full-GPU viability is quantization-specific: Q4 256K/Q8 fits this RTX 5090, while Q5 256K/Q8 did not meet throughput expectations.
- Restrict model control to fixed profiles and validate each rollback profile before deleting a replaced model artifact.
- Keep long-context Q4 at one parallel slot until a dedicated concurrency test proves memory headroom.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/plan.md`
- `log`: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/log.md`
- `tasks`: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/tasks.md`
- `rfc`: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/review-rfc.md`, `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/review-change.md`
- `verification`: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/test-report.md`
- `report`: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/report-walkthrough.md`
