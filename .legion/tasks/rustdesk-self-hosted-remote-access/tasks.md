# RustDesk 自托管远程访问 - 任务清单

## 快速恢复

**当前阶段**: 阶段 4 - 证据收口与PR lifecycle
**当前检查项**: 提交、检查并squash merge最终same-intranet relay/Charlie v10 PR
**进度**: 3/4 任务完成
---

## 阶段 1: 设计与安全门禁 ✅ COMPLETE

- [x] 完成1.4.9安全修订与对抗审查 | 验收: RFC覆盖cargo vendor override、fallback-resistant public config proof、manual-finalize状态机、fixed-forward边界且Round 7 review-rfc PASS
---

## 阶段 2: 实现与静态验证 ✅ COMPLETE

- [x] 在隔离 worktree 实现三台主机配置，完成构建、安全评审并合并配置 PR | 验收: 配置 PR #139 已合并为 `0026eb99`，不包含明文秘密
---

## 阶段 3: 生产部署 ✅ COMPLETE

- [x] 完成三端switch与运行时验证 | 验收: Acorn same-intranet会话强制进入hbbr；Axiom保留可用fallback；Charlie v10画面/输入、正确/错误密码、manual finalize与fast-skip全部PASS
---

## 阶段 4: 证据收口 🔄 IN PROGRESS

- [ ] 提交部署证据、walkthrough 与 wiki writeback并完成 follow-up PR lifecycle | 验收: evidence PR 到达终态，blocking review 已处理，worktree 清理且主工作区刷新 ← CURRENT
---

## 发现的新任务

- [x] Axiom runtime fixed-forward与portal/cursor containment完成
- [x] Acorn same-intranet force-relay source patch与Charlie v10 GUI-domain restart完成
---

*最后更新: 2026-07-15*
