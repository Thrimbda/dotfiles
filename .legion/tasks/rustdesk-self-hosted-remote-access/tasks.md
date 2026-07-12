# RustDesk 自托管远程访问 - 任务清单

## 快速恢复

**当前阶段**: 阶段 2 - 1.4.9 实现与静态验证
**当前检查项**: 创建配置PR、通过checks/review并merge
**进度**: 1/4 任务完成
---

## 阶段 1: 设计与安全门禁 ✅ COMPLETE

- [x] 完成1.4.9安全修订与对抗审查 | 验收: RFC覆盖cargo vendor override、fallback-resistant public config proof、manual-finalize状态机、fixed-forward边界且Round 7 review-rfc PASS
---

## 阶段 2: 实现与静态验证 🔄 IN PROGRESS

- [ ] 在隔离 worktree 实现三台主机配置，完成构建、安全评审并合并配置 PR | 验收: 改动严格位于 contract scope，不包含明文秘密，配置 PR 已合并且主工作区刷新到 merged commit ← CURRENT
---

## 阶段 3: 生产部署 ⏳ NOT STARTED

- [ ] 从 clean merged baseline 依次 switch acorn、axiom、charlie并执行运行时验证 | 验收: 三台目标机完成可验证部署，或部分失败被回滚且阻塞被清晰记录
---

## 阶段 4: 证据收口 ⏳ NOT STARTED

- [ ] 提交部署证据、walkthrough 与 wiki writeback并完成 follow-up PR lifecycle | 验收: evidence PR 到达终态，blocking review 已处理，worktree 清理且主工作区刷新
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-07-12*
