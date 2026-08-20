# Deploy Q6 128K Qwen with model control - 任务清单

## 快速恢复

**当前阶段**: (none)
**当前检查项**: (none)
**进度**: 6/6 任务完成
---

## 阶段 1: Design ✅ COMPLETE

- [x] Specify and review the Q6 selection and service-control design | 验收: RFC defines selection persistence, command contract, failure handling, verification, and rollback and passes review
---

## 阶段 2: Implementation ✅ COMPLETE

- [x] Add Q6 selection and qwen-model control to Axiom | 验收: Generated service defaults to active.gguf and qwen-model exposes only bounded subcommands
- [x] Download and verify the Q6 artifact | 验收: The exact standard Q6 MTP file exists with the upstream SHA-256
---

## 阶段 3: Verification ✅ COMPLETE

- [x] Merge, activate, and verify Q6 128K | 验收: Q6 loads fully on CUDA and health, chat, MTP, context, and GPU checks pass
- [x] Verify qwen-model lifecycle and quantization switching | 验收: status/start/stop/restart and Q6-Q4-Q6 switching pass with only one model loaded
---

## 阶段 4: Closeout ✅ COMPLETE

- [x] Review and record the Q6 deployment | 验收: Review, walkthrough, task log, and wiki current truth are complete
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-20 08:03*
