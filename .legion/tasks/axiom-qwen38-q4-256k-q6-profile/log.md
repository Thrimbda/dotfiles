# Axiom Qwen Q4 256K 与 Q6 档位 - 日志

## 会话进展 (2026-08-23)

### ✅ 已完成

- 完成 Q4/Q6-only 配置、Q4 CPU-only MTP 加载与完整 NixOS build。
- 创建 Draft PR #201。

(暂无)
### 🟡 进行中

- 初始化任务日志。
- 等待交互式 Q4 migration 和新 generation 运行时验证。
### ⚠️ 阻塞/待定

- 当前 agent 会话无 sudo TTY；active link 仍指向 Q5，必须先由交互式 qwen-model q4 迁移。

(暂无)
---

## 关键文件

(暂无)
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| (暂无) | - | - | - |
---

## 快速交接

**下次继续从这里开始：**

1. 在 /home/c1/dotfiles/.worktrees/axiom-qwen38-q4-256k-q6-profile 执行 qwen-model q4。
2. 确认 Q4 healthy 后执行 sudo nixos-rebuild switch --flake .#axiom。
3. 把两步输出交回以继续 Q4/Q6 吞吐、fallback 与 Q5 删除验证。

**注意事项：**

- Draft PR: https://github.com/Thrimbda/dotfiles/pull/201。
- Q5 文件尚未删除；这是刻意保留的迁移回滚点。
---

*最后更新: 2026-08-23 05:52 by Legion CLI*
