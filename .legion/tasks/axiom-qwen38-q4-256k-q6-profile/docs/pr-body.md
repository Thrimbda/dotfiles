## Summary

- Make Q4_K_M the default full-GPU Qwen profile at 262144 tokens with Q8 K/V cache.
- Retain Q6_K as the full-GPU 131072-token high-precision profile with Q4 K/V cache.
- Remove all Q5 configuration and model-control paths.

## Static Validation

- `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null`
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- CPU-only MTP load of `RVN-Q4_K_M-mtp.gguf`
- Generated launcher inspection confirms only Q4/Q6 targets, each with `--n-gpu-layers all`.
- Deployed Q4 full GPU profile: 107.91 tok/s, 96-97% GPU SM utilization, and roughly one CPU core during a 1024-token generation.
- Switched Q6 128K fallback successfully and returned to Q4; Q5 command surface and 19.7GB model artifact are removed.

## Operational Boundary

Q4 256K/Q8 uses about 30,970 MiB / 32,607 MiB VRAM. Keep `--parallel 1`; profile higher concurrency before changing it. Full evidence: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/test-report.md`.
