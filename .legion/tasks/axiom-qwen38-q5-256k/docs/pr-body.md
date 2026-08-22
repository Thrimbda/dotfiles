## Summary

- Add the RVN Q5_K_M MTP artifact as a controlled Qwen target and default seed.
- Run Q4/Q5 with 262144-token Q8 KV cache; preserve Q6 with its working 131072-token Q4 profile.
- Retain atomic model switching and automatic rollback on startup or health-check failure.

## Validation

- `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null`
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Validated the realized launcher contains the intended Q4/Q5 and Q6 profiles.
- Downloaded `RVN-Q5_K_M-mtp.gguf` with SHA-256 `ce34015241702a9258c8cbca64012bf03a05fda919ebd1c6613d88773d71245b`.

## Blocked Deployment Verification

Current session cannot supply the interactive sudo password required by `nixos-rebuild switch`. The active Q6 service remains healthy. To complete runtime validation on Axiom, switch this generation, run `qwen-model q5`, verify the health endpoint/API/GPU allocation, then run `qwen-model q6` to verify rollback. Details: `.legion/tasks/axiom-qwen38-q5-256k/docs/test-report.md`.
