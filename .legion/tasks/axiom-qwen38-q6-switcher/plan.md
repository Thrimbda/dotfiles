# Deploy Q6 128K Qwen with model control

## 目标

Replace the default Axiom Qwen deployment with the standard Q6_K MTP model at 128K while retaining Q4 on disk and providing one command to select Q4/Q6 and control the service.

## 问题陈述

The current service hardcodes the Q4 model path and has no supported operator command for selecting quantization or controlling model residency.

## 验收标准

- [ ] RVN-Q6_K-mtp.gguf is downloaded and checksum-verified outside the Nix store
- [ ] The service defaults to Q6 through a mutable active.gguf selection and retains 131072 context, full CUDA offload, Q4 KV, flash attention, and MTP
- [ ] qwen-model supports q4, q6, start, stop, restart, and status with clear errors
- [ ] The complete Axiom closure builds and the merged switch succeeds
- [ ] Q6 runtime reports 131072, health/chat/tool calls pass, and GPU telemetry shows no CPU fallback or OOM
- [ ] Switching Q6 to Q4 and back to Q6 succeeds without concurrent model residency
- [ ] OpenCode keeps the same provider/model entry and 131072 context

## 假设 / 约束 / 风险

- **假设**: The standard RVN-Q6_K-mtp.gguf artifact remains publicly available with LFS SHA-256 4e47a0e41992de4bed56a3395f6c7e1adb760a1875ed84f836f67d65b2f646ef
- **假设**: Projected Q6 full-GPU usage of roughly 26GiB leaves sufficient runtime headroom on the 32GB RTX 5090
- **假设**: The operator can authorize systemctl operations through sudo
- **约束**: Only one Qwen model may be resident at a time
- **约束**: Keep both model artifacts outside the Nix store
- **约束**: Default selection after deployment is Q6
- **约束**: Keep the API endpoint and OpenCode model ID unchanged
- **约束**: Do not change context, KV type, MTP depth, sampling, authentication, or network exposure
- **约束**: Do not touch unrelated secrets or worktrees
- **风险**: Q6 may exceed projected VRAM during load or long-context compute
- **风险**: A broken or dangling selection symlink could prevent service startup
- **风险**: Model switching interrupts active inference requests
- **风险**: A wrapper using sudo must not accept arbitrary paths or commands

## 要点

- 待补充

## 范围

- Download and verify the standard Q6 MTP artifact
- Introduce a fixed-target active model selection boundary
- Add the qwen-model operator command
- Build, merge, activate, and verify Q6 plus round-trip Q4/Q6 switching
- Record review, verification, walkthrough, and wiki evidence

## 设计索引 (Design Index)

> **Design Source of Truth**: （暂无）

**摘要**:
- Use active.gguf as the only service model path and restrict the command to two hardcoded artifacts
- Seed active.gguf to Q6 only when absent so operator selection persists across rebuilds
- Use sudo systemctl for explicit lifecycle operations rather than killing the process as a control API
- Keep OpenCode model identity stable because the served logical model is unchanged

## 阶段概览

1. **Design** - Specify and review the Q6 selection and service-control design
2. **Implementation** - Add Q6 selection and qwen-model control to Axiom
3. **Verification** - Merge, activate, and verify Q6 128K
4. **Closeout** - Review and record the Q6 deployment

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*
