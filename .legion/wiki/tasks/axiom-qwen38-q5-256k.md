# axiom-qwen38-q5-256k

## Metadata

- `task-id`: `axiom-qwen38-q5-256k`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-qwen38-q6-switcher`
- `superseded-by`: `(none)`

## Outcome Summary

Axiom now runs Qwen 3.8 27B with the repaired RVN Q5_K_M MTP artifact, 262144-token native context, and Q8 K/V cache. The service is active, healthy, and returns a real OpenAI-compatible API completion.

The 32GB RTX 5090 uses 30,665 MiB for the one-slot profile. llama.cpp chooses layer placement through default `--fit`; Q5 must not force `--n-gpu-layers all` at this context length.

Q6 remains the 128K/Q4 rollback profile. The former Q6-default task is historical, but its fixed-target model-control and atomic-recovery rules remain active.

## Reusable Decisions

- Validate a new GGUF with llama.cpp before activation even when its upstream SHA-256 matches.
- Bind long-context cache precision to a model profile, and leave GPU layer count unset when KV cache leaves narrow VRAM headroom.
- Keep one parallel slot at the measured 256K/Q8 capacity until a dedicated concurrency profile proves more headroom.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-qwen38-q5-256k/plan.md`
- `log`: `.legion/tasks/axiom-qwen38-q5-256k/log.md`
- `tasks`: `.legion/tasks/axiom-qwen38-q5-256k/tasks.md`
- `rfc`: `.legion/tasks/axiom-qwen38-q5-256k/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-qwen38-q5-256k/docs/review-rfc.md`, `.legion/tasks/axiom-qwen38-q5-256k/docs/review-change.md`
- `verification`: `.legion/tasks/axiom-qwen38-q5-256k/docs/test-report.md`
- `report`: `.legion/tasks/axiom-qwen38-q5-256k/docs/report-walkthrough.md`
