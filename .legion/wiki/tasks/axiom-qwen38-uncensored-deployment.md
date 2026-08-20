# axiom-qwen38-uncensored-deployment

## Metadata

- `task-id`: `axiom-qwen38-uncensored-deployment`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Axiom now has a merge-ready NixOS configuration for a loopback-only Qwen3.8 27B uncensored inference service. It pins CUDA-enabled llama.cpp b10472 because the previous nixpkgs build predates required MTP support. The selected model and template are stored outside the Nix store and passed checksum, CUDA, MTP, 64K context, and OpenAI-compatible API runtime checks. The task remains active until the merged configuration is switched interactively and the persistent system service is verified.

## Reusable Decisions

- Prefer a narrow llama.cpp source override over adding the upstream flake when the nixpkgs package expression already supplies the needed CUDA integration.
- Keep large mutable model artifacts outside the Nix store and gate service startup with `ConditionPathExists`.
- Keep this unauthenticated local inference endpoint bound to `127.0.0.1`; use port 8081 because Gatus owns 8080.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-qwen38-uncensored-deployment/plan.md`
- `log`: `.legion/tasks/axiom-qwen38-uncensored-deployment/log.md`
- `tasks`: `.legion/tasks/axiom-qwen38-uncensored-deployment/tasks.md`
- `rfc`: `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/rfc.md`
- `reviews`: `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/review-rfc.md`, `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/review-change.md`
- `verification`: `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/test-report.md`
- `report`: `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/report-walkthrough.md`

## Notes

- Post-merge activation is tracked in `.legion/wiki/maintenance.md`.
