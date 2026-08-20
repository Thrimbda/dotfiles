# Verification Report

## Result

PASS. The Axiom closure, merged activation, persistent 131072-token service, GPU capacity, MTP, API, restart recovery, and matching global OpenCode configuration all pass.

## Model Capacity Evidence

The deployed GGUF reports `qwen35.context_length = 262144` and `n_ctx_train = 262144`, so 131072 remains within the model-native context and requires no RoPE override.

## NixOS Closure

```bash
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel -L
```

Passed. The complete Axiom closure is `/nix/store/qz1a22msdqzxlnjm5fmf2rz7whvrih88-nixos-system-axiom-26.05.7813.0dd31db7e6db`. This full closure build was chosen over evaluation-only checks because it proves that the changed service composes with the complete host configuration.

## Generated Unit

The built unit contains `--ctx-size 131072` while retaining full GPU offload, flash attention, one slot, Q4_0 K/V cache, MTP depth 2, loopback port 8081, and the existing model/template paths.

## Post-Merge Runtime

- PR #173 merged at `62aa3c77`; the NixOS switch from refreshed `origin/master` succeeded.
- `/props` reports `n_ctx = 131072` and one slot.
- Logs report `n_ctx_slot = 131072`, MTP draft-context creation, and successful model load.
- `/health` and chat completion pass with a separate reasoning field.
- RTX 5090 usage is 20,483 MiB with 11,595 MiB free.
- After `SIGKILL`, systemd changed PID `196767` to `327584`, incremented `NRestarts` to 1, and restored the healthy 131072-token service.

## OpenCode

The global `qwen-local/qwen3.8-27b-uncensored` declaration now reports context 131072 while retaining output 16384 and low/medium/xhigh reasoning variants. OpenCode model enumeration, a medium-effort text request, and a low-effort Bash tool call all passed.
