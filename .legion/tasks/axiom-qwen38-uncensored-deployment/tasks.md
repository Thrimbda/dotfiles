# Deploy Qwen3.8 uncensored on Axiom - 任务清单

## 快速恢复

**当前阶段**: (none)
**当前检查项**: (none)
**进度**: 6/6 任务完成
---

## 阶段 1: Design ✅ COMPLETE

- [x] Record and review the deployment design | 验收: RFC captures package source, service contract, verification, and rollback and passes review
---

## 阶段 2: Implementation ✅ COMPLETE

- [x] Package current CUDA llama.cpp and add the Axiom service | 验收: Axiom configuration exposes a valid qwen3-8-27b systemd unit
- [x] Download the selected model and chat template | 验收: Both required artifacts exist at the configured paths
---

## 阶段 3: Verification ✅ COMPLETE

- [x] Evaluate and switch the NixOS configuration | 验收: The Axiom switch succeeds without regressing existing services
- [x] Verify service, CUDA, MTP, and API behavior | 验收: Health, logs, GPU telemetry, and a chat completion all pass
---

## 阶段 4: Closeout ✅ COMPLETE

- [x] Review delivery evidence and update reusable knowledge | 验收: Review, walkthrough, and wiki writeback are complete
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-20 05:13*
