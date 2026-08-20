# Expand Axiom Qwen context to 128K

## 目标

Raise the effective local Qwen context from 65536 to 131072 tokens in both llama-server and OpenCode while preserving full CUDA inference, MTP, and service reliability.

## 问题陈述

The deployed llama-server and OpenCode provider currently cap the model at 65536 tokens despite the GGUF supporting 262144.

## 验收标准

- [ ] The Axiom service is configured with ctx-size 131072 and the complete NixOS closure builds
- [ ] The merged configuration switches successfully and qwen3-8-27b.service is enabled and active
- [ ] Runtime props and logs report a 131072-token slot with MTP enabled
- [ ] Health, chat completion, and automatic service restart continue to pass
- [ ] RTX 5090 memory usage remains within capacity without CPU fallback or OOM
- [ ] OpenCode declares context 131072 and can complete a model and tool-call request

## 假设 / 约束 / 风险

- **假设**: The GGUF metadata value qwen35.context_length=262144 is authoritative
- **假设**: Q4_0 K/V cache at 128K fits alongside model weights, MTP state, compute buffers, and desktop GPU use on the 32GB RTX 5090
- **假设**: Single-slot operation remains appropriate
- **约束**: Keep full GPU offload, flash attention, Q4_0 K/V cache, MTP depth 2, and loopback port 8081
- **约束**: Do not change the default OpenCode model
- **约束**: Do not alter the 16384-token OpenCode output limit
- **约束**: Do not attempt 256K, change model quantization, add parallel slots, authentication, Web UI, or public exposure
- **约束**: Do not touch unrelated untracked secrets or worktrees
- **风险**: 128K KV allocation may consume more VRAM than projected and fail startup
- **风险**: Long prompt ingestion will be slower
- **风险**: The global OpenCode config is outside the repository and must be updated only after the merged service configuration is activated

## 要点

- 待补充

## 范围

- Update the Axiom llama-server context setting
- Build, merge, activate, and verify the persistent service at 128K
- Update and verify the global OpenCode model context declaration
- Record verification, review, walkthrough, and wiki evidence

## 设计索引 (Design Index)

> **Design Source of Truth**: （暂无）

**摘要**:
- Use the model-native context directly without RoPE overrides because 131072 is below n_ctx_train=262144
- Retain Q4_0 K/V cache to limit the linear context-memory increase
- Deploy from merged origin/master before updating OpenCode metadata

## 阶段概览

1. **Implementation** - Set the Axiom Qwen service context to 131072
2. **Verification** - Merge, activate, and verify the 128K service
3. **Closeout** - Review and record the completed 128K deployment

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*
