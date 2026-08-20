# Deploy Qwen3.8 uncensored on Axiom - 日志

## 会话进展 (2026-08-20)

### ✅ 已完成

- Task contract materialized
- Deployment RFC reviewed PASS
- Pinned and built CUDA llama.cpp b10472
- Added the qwen3-8-27b systemd service
- Downloaded and checksum-verified the selected model and chat template
- Verified health, model listing, MTP initialization, CUDA loading, and chat completion with a transient service
- Task contract and reviewed RFC
- Pinned and built CUDA llama.cpp b10472
- Added the qwen3-8-27b systemd service
- Downloaded and checksum-verified the model and chat template
- Verified health, model listing, MTP initialization, CUDA loading, and chat completion with a transient service
- Completed change review, delivery walkthrough, PR body, and active wiki writeback

(暂无)
### 🟡 进行中

- 初始化任务日志。
- Pin llama.cpp b10472 and add the Axiom service
- Activate the built Axiom configuration interactively and verify the system service
- Merge the PR, refresh the main workspace, then activate and verify the persistent service
### ⚠️ 阻塞/待定

- 约束: Port 8080 is occupied by Gatus; bind the Qwen API to 127.0.0.1:8081.
- The local NixOS switch requires a sudo password that the non-interactive session cannot provide
- 约束: System activation is blocked on interactive sudo authentication; the verified transient user service was stopped after testing.
- The final NixOS switch requires interactive sudo authentication

(暂无)
---

## 关键文件

- **`.legion/tasks/axiom-qwen38-uncensored-deployment/docs/review-change.md`** [completed]
  - 作用: Record the read-only implementation review decision
  - 备注: PASS with no blocking findings; persistent service activation remains a post-merge check
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Merge the verified configuration before system activation | The user wants the deployed system to be sourced from the final merged master branch rather than the feature worktree | Activate from the feature worktree before PR delivery | 2026-08-20 |
---

## 快速交接

**下次继续从这里开始：**

1. Commit, rebase, push, open and merge the PR
2. Refresh /home/c1/dotfiles to merged origin/master
3. Run sudo nixos-rebuild switch --flake .#axiom -L interactively from /home/c1/dotfiles
4. Verify qwen3-8-27b.service, health, chat, MTP logs, and GPU telemetry

**注意事项：**

- The exact generated command already passed runtime verification as a transient user service
- The model and chat template are present at the configured paths

(暂无)
(暂无)
---

*最后更新: 2026-08-20 04:34 by Legion CLI*
