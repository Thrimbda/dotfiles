# Axiom Qwen Q4 256K 与 Q6 档位 - 日志

## 会话进展 (2026-08-23)

### ✅ 已完成

- 完成 Q4/Q6-only 配置、Q4 CPU-only MTP 加载与完整 NixOS build。
- 创建 Draft PR #201。
- 部署 Q4 256K/Q8 全 GPU profile，实测 107.91 tok/s、GPU SM 96-97%、CPU 约单核。
- 验证 Q6 128K/Q4 fallback 并恢复 Q4。
- 删除 Q5 配置、控制命令和本机模型工件，完成 report 与 wiki writeback。

(暂无)
### 🟡 进行中

- 初始化任务日志。
- 等待交互式 Q4 migration 和新 generation 运行时验证。
- 更新 PR 并跟进 merge lifecycle。
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

1. 提交运行时验证与 wiki evidence，更新 PR #201。
2. 将 PR 标记 ready，尝试 auto-merge，跟进终态后清理 worktree 并刷新主工作区。

**注意事项：**

- Current live profile: Q4 262144/Q8/full GPU; Q6 remains the 131072/Q4 full-GPU high-precision option。
- Q5 artifact removed after both Q4 and Q6 runtime checks passed。
---

*最后更新: 2026-08-24 03:24 by Legion CLI*
