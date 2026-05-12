# Hlissner-aligned Dotfiles Architecture Cleanup - 任务清单

## 快速恢复
**当前阶段**: Phase 5 - PR Delivery and Writeback
**当前检查项**: 等待 PR review / 用户 merge 决策
**进度**: 15/16 任务完成

---

## Phase 1: Contract and Research ✅ COMPLETE
- [x] 物化 Legion task contract | 验收: `plan.md` 和 `tasks.md` 完整记录目标、范围、约束、风险和阶段
- [x] 记录当前仓库结构研究 | 验收: `docs/research.md` 引用当前仓库关键文件和 Legion wiki 当前真源
- [x] 记录 hlissner/dotfiles 架构对照 | 验收: `docs/research.md` 说明可借鉴模式和不可导入边界

## Phase 2: RFC and Review ✅ COMPLETE
- [x] 产出架构清理 RFC | 验收: `docs/rfc.md` 含 options、decision、scope、rollback、verification
- [x] 完成 RFC review | 验收: `docs/review-rfc.md` 为 PASS；否则回到 RFC

## Phase 3: Worktree Implementation ✅ COMPLETE
- [x] 启动 git-worktree-pr envelope | 验收: 修改型工作在隔离 worktree/branch 中进行
- [x] 按 RFC 执行最小架构清理 | 验收: diff 限于批准 scope，功能变化显式记录
- [x] 更新相关文档和任务日志 | 验收: docs/log 与实现决策一致

## Phase 4: Verification and Readiness Review ✅ COMPLETE
- [x] 运行 Nix/静态验证 | 验收: `docs/test-report.md` 记录命令、结果、不可验证项和 follow-up smoke
- [x] 修复验证发现的实现缺口 | 验收: 验证重新通过或记录阻塞
- [x] 完成 change readiness review | 验收: `docs/review-change.md` 为 PASS；否则回到实现或设计

## Phase 5: PR Delivery and Writeback 🟡 IN PROGRESS
- [x] 生成 reviewer walkthrough | 验收: `docs/report-walkthrough.md` 可供 reviewer 快速审查
- [x] 生成 PR body | 验收: `docs/pr-body.md` 可直接用于 PR
- [x] 创建 PR 但不自动合并 | 验收: PR URL 记录在 log/report 中: https://github.com/Thrimbda/dotfiles/pull/43
- [x] 完成 Legion wiki writeback | 验收: `.legion/wiki` 记录可复用架构清理模式和任务摘要
- [ ] 跟进 checks/review 终态 | 验收: PR 当前 open，无 reported required checks，无 review decision；按用户要求不自动合并，worktree cleanup 和主工作区刷新等待 PR 终态 ← CURRENT
