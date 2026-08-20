# Deploy Qwen3.8 uncensored on Axiom - 日志

## 会话进展 (2026-08-20)

### ✅ 已完成

- Task contract and reviewed RFC
- Pinned and built CUDA llama.cpp b10472
- Added the qwen3-8-27b systemd service
- Downloaded and checksum-verified the model and chat template
- Verified health, model listing, MTP initialization, CUDA loading, and chat completion with a transient service
- Completed change review, delivery walkthrough, PR body, and active wiki writeback
- PR #171 merged at 593576f3
- Switched Axiom from merged origin/master
- Verified the persistent enabled service, health, models, chat, CUDA residency, MTP, 64K context, and automatic restart recovery
- Completed final review, walkthrough, and wiki writeback

### 🟡 进行中

(暂无)
### ⚠️ 阻塞/待定

(暂无)
---

## 关键文件

- **`.legion/tasks/axiom-qwen38-uncensored-deployment/docs/test-report.md`** [completed]
  - 作用: Record final build, activation, runtime, and restart verification
  - 备注: Final result PASS
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Merge the verified configuration before system activation | Deploy from the final merged master branch rather than a feature worktree | Activate from the feature worktree before PR delivery | 2026-08-20 |
---

## 快速交接

**下次继续从这里开始：**

1. (none)

**注意事项：**

- Deployment complete at http://127.0.0.1:8081
- Model ID: qwen3.8-27b-uncensored
- PR #171 merged
---

*最后更新: 2026-08-20 05:14 by Legion CLI*
