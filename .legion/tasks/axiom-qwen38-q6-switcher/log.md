# Deploy Q6 128K Qwen with model control - 日志

## 会话进展 (2026-08-20)

### ✅ 已完成

- Materialized and reviewed the Q6 model-control design
- Implemented active.gguf selection and qwen-model control
- Built the complete Axiom closure and passed ShellCheck
- Downloaded and checksum-verified the standard Q6 MTP artifact
- Recorded partial verification, change review PASS, walkthrough, PR body, and active wiki writeback

(暂无)
### 🟡 进行中

- 初始化任务日志。
- Merge, activate, and verify Q6 plus lifecycle/model switching
### ⚠️ 阻塞/待定

(暂无)

(暂无)
---

## 关键文件

- **`hosts/axiom/default.nix`** [completed]
  - 作用: Add active model selection, Q6 defaulting, and bounded qwen-model control
  - 备注: Complete closure and ShellCheck pass
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Use one service with a fixed-target active.gguf selector | This preserves Q4 rollback and Q6 defaulting without allowing concurrent VRAM/port ownership or arbitrary privileged paths | Hardcode Q6; run separate Q4/Q6 services; accept arbitrary model paths | 2026-08-20 |
---

## 快速交接

**下次继续从这里开始：**

1. Commit, rebase, push, and merge the Q6 control change
2. Switch Axiom from merged origin/master
3. Verify Q6 128K full-GPU runtime and qwen-model lifecycle/switching
4. Complete closeout evidence

**注意事项：**

- Q6 artifact is present and matches upstream SHA-256
- Q4 remains running until merged activation
---

*最后更新: 2026-08-20 07:10 by Legion CLI*
