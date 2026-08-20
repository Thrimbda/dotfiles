# Deploy Qwen3.8 uncensored on Axiom

## 目标

Run the RVN Q4 MTP uncensored Qwen3.8-27B model as a persistent CUDA-backed OpenAI-compatible local service on Axiom.

## 问题陈述

Axiom has suitable GPU capacity but no current llama.cpp runtime, model artifact, or persistent inference service. The pinned nixpkgs llama.cpp build is older than the model MTP requirement.

## 验收标准

- [ ] Axiom NixOS configuration evaluates and deploys a CUDA-enabled llama.cpp build new enough for Qwen3.8 MTP
- [ ] RVN-Q4_K_M-mtp.gguf and chat_template.jinja are downloaded outside the Nix store under the c1 user data directory
- [ ] qwen3-8-27b.service is active on 127.0.0.1:8081 and survives restart
- [ ] The OpenAI-compatible chat completions endpoint returns a valid response
- [ ] Runtime evidence confirms RTX 5090 GPU offload and draft-mtp speculative decoding

## 假设 / 约束 / 风险

- **假设**: The selected Hugging Face repository and RVN-Q4_K_M-mtp artifact remain available without authentication
- **假设**: Single-user, single-request throughput is the primary workload
- **假设**: 64K context with Q4 KV cache fits alongside the model on the 32 GB RTX 5090
- **约束**: Keep the deployment minimal and Axiom-local
- **约束**: Do not add Docker, Open WebUI, reverse proxy, authentication, or public network exposure
- **约束**: Do not store the multi-gigabyte model in the Nix store
- **约束**: Do not modify unrelated existing worktree or secret files
- **风险**: Building a newer CUDA llama.cpp revision may be slow or fail against the current Nix CUDA toolchain
- **风险**: The community abliterated model may regress capabilities relative to the official model
- **风险**: The model download is large and may be interrupted
- **风险**: GPU memory already used by desktop workloads may reduce runtime headroom

## 要点

- Use the existing RTX 5090 and current NixOS NVIDIA stack
- Prefer the smallest maintainable service configuration
- Keep rollback to removing one host service and its package source override

## 范围

- flake inputs or package source override needed for a current llama.cpp build
- hosts/axiom/default.nix systemd service configuration
- Local model files under /home/c1/.local/share/models/qwen3.8-27b
- Axiom deployment and runtime verification

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- Reuse the current nixpkgs llama-cpp package definition with CUDA enabled and pin only a sufficiently new upstream source revision
- Run llama-server directly as user c1 under systemd on localhost port 8081
- Use one 64K slot, full GPU offload, flash attention, Q4 KV cache, embedded MTP depth 2, and medium reasoning effort
- Keep model acquisition as a one-time mutable data download outside Nix

## 阶段概览

1. **Design** - Record and review the deployment design
2. **Implementation** - Package current CUDA llama.cpp and add the Axiom service
3. **Verification** - Evaluate and switch the NixOS configuration
4. **Closeout** - Review delivery evidence and update reusable knowledge

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*
