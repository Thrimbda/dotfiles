# Deploy Q6 128K Qwen with model control - 日志

## 会话进展 (2026-08-20)

### ✅ 已完成

- Materialized and reviewed the Q6 model-control design
- Implemented active.gguf selection and qwen-model control
- Built the complete Axiom closure and passed ShellCheck
- Downloaded and checksum-verified the standard Q6 MTP artifact
- Recorded partial verification, change review PASS, walkthrough, PR body, and active wiki writeback
- Merged and activated Q6 model selection in PR #175
- Found the non-setuid store-sudo failure safely and corrected it in PR #176
- Verified Q6 128K MTP runtime with 6629 MiB GPU headroom
- Verified direct reasoning, OpenCode Bash tool use, lifecycle controls, and Q6-Q4-Q6 switching
- Finalized FULL PASS verification, review, walkthrough, PR body, and completed wiki truth

### 🟡 进行中

(暂无)
### ⚠️ 阻塞/待定

(暂无)
---

## 关键文件

- **`hosts/axiom/default.nix`** [completed]
  - 作用: Add active model selection, Q6 defaulting, and bounded qwen-model control
  - 备注: Merged, activated, and runtime-verified
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Use one service with a fixed-target active.gguf selector | This preserves Q4 rollback and Q6 defaulting without allowing concurrent VRAM/port ownership or arbitrary privileged paths | Hardcode Q6; run separate Q4/Q6 services; accept arbitrary model paths | 2026-08-20 |
---

## 快速交接

**下次继续从这里开始：**

1. No task-local implementation or verification work remains

**注意事项：**

- Final deployment is healthy Q6; use qwen-model q4 for rollback and qwen-model q6 to restore the preferred model
---

*最后更新: 2026-08-20 08:03 by Legion CLI*
