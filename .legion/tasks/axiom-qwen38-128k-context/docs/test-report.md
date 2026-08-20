# Verification Report

## Result

PARTIAL PASS. The Axiom closure and generated service validate at 131072 tokens. Runtime activation, GPU capacity, persistent-service checks, and the matching global OpenCode update remain post-merge checks.

## Model Capacity Evidence

The deployed GGUF reports `qwen35.context_length = 262144` and `n_ctx_train = 262144`, so 131072 remains within the model-native context and requires no RoPE override.

## NixOS Closure

```bash
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel -L
```

Passed. The complete Axiom closure is `/nix/store/qz1a22msdqzxlnjm5fmf2rz7whvrih88-nixos-system-axiom-26.05.7813.0dd31db7e6db`. This full closure build was chosen over evaluation-only checks because it proves that the changed service composes with the complete host configuration.

## Generated Unit

The built unit contains `--ctx-size 131072` while retaining full GPU offload, flash attention, one slot, Q4_0 K/V cache, MTP depth 2, loopback port 8081, and the existing model/template paths.

## Pending Checks

- Merge and switch the configuration from refreshed `origin/master`.
- Confirm `/props` reports `n_ctx = 131072` and logs report `n_ctx_slot = 131072` with MTP initialization.
- Confirm health, chat completion, automatic restart recovery, and RTX 5090 memory headroom.
- Change the global OpenCode model context from 65536 to 131072 and verify model and tool-call requests.
