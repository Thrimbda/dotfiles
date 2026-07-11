# Dotfiles Caelestia-only Bluetooth Control - 任务清单

## 快速恢复

**当前阶段**: 阶段 4 - Delivery
**当前检查项**: 完成代码审查与 walkthrough
**进度**: 6/8 任务完成
---

## 阶段 1: Design ✅ COMPLETE

- [x] 记录现状证据并形成 RFC | 验收: RFC 定义唯一控制面、AuthAgent 边界、迁移与验证策略
- [x] 完成 RFC 对抗审查 | 验收: review-rfc 通过且无未解决阻塞
---

## 阶段 2: Implementation ✅ COMPLETE

- [x] 在隔离 worktree 中实现全局控制面精简 | 验收: Blueman/Rofi 可见控制面移除且 headless agent 保留
- [x] 实现 Caelestia 名称排序与 blocked 状态策略 | 验收: 真实名称优先且开关不被 stale soft block 卡死
---

## 阶段 3: Verification ✅ COMPLETE

- [x] 验证多主机求值与 Axiom 构建 | 验收: 所有 bluetooth hosts 求值通过且 Axiom toplevel 构建成功
- [x] 验证 headless AuthAgent、无额外 UI 与运行时蓝牙状态 | 验收: 静态与运行时证据覆盖 agent、UI 唯一性和蓝牙状态
---

## 阶段 4: Delivery ⏳ NOT STARTED

- [ ] 完成代码审查与 walkthrough | 验收: review-change 通过且报告可供评审 ← CURRENT
- [ ] 创建并跟进 PR、合并、清理和 wiki 写回 | 验收: PR 到达终态，worktree 清理且 wiki 更新
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-07-11 21:12*
