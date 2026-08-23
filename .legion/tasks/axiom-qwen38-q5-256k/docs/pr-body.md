## Summary

- Add the RVN Q5_K_M MTP artifact as a controlled Qwen target and default seed.
- Run Q4/Q5 with 262144-token Q8 KV cache; preserve Q6 with its working 131072-token Q4 profile.
- Let llama.cpp's default `--fit` automatically offload excess weights rather than forcing all Q5 weights onto the 32GB GPU.
- Retain atomic model switching and automatic rollback on startup or health-check failure.

## Validation

- `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null`
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Validated the realized launcher contains the intended Q4/Q5 and Q6 profiles, with no forced GPU layer count.
- Replaced an upstream-invalid Q5 MTP artifact with fixed revision `3d0bfd5`; SHA-256 `ef6c307c53da1e0a577b27df0b636c2818880aabe5c132f423a404e36b391365` and a CPU-only MTP load both pass.
- Deployed and selected Q5 successfully: 262144-token/Q8 profile, health endpoint, OpenAI-compatible API, and RTX 5090 memory usage all pass.

## Operational Boundary

Q5 uses 30,665 MiB / 32,607 MiB GPU memory. Keep one parallel slot and do not increase concurrency without re-profiling. Details: `.legion/tasks/axiom-qwen38-q5-256k/docs/test-report.md`.
