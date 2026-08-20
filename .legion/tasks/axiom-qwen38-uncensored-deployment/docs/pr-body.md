## Summary

- pin CUDA-enabled `llama.cpp` b10472 for current MTP support
- add a loopback-only Axiom systemd service for the Qwen3.8 27B uncensored GGUF
- configure 64K context, full GPU offload, Q4 KV cache, flash attention, one slot, and MTP depth 2

## Verification

- complete `.#nixosConfigurations.axiom.config.system.build.toplevel` closure built successfully
- model SHA-256 matches the upstream Hugging Face LFS object
- b10472 detects the RTX 5090 CUDA device
- transient run of the generated command passed `/health`, `/v1/models`, and `/v1/chat/completions`
- logs confirmed MTP draft context and a 65536-token slot
- change review: PASS, no blocking findings

## Deployment

PR #171 merged and the NixOS switch from merged `origin/master` succeeded. `qwen3-8-27b.service` is enabled and active; health, chat, CUDA/MTP logs, GPU residency, and automatic restart recovery all pass.

## Evidence

- `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/rfc.md`
- `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/test-report.md`
- `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/review-change.md`
- `.legion/tasks/axiom-qwen38-uncensored-deployment/docs/report-walkthrough.md`
