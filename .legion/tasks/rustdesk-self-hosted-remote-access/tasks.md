# RustDesk 自托管远程访问 - 任务清单

## 快速恢复

**当前阶段**: 阶段 3 - 生产部署（Axiom fixed-forward）
**当前检查项**: 提交、检查并合并Axiom-only fixed-forward hotfix PR
**进度**: 2/4 任务完成
---

## 阶段 1: 设计与安全门禁 ✅ COMPLETE

- [x] 完成1.4.9安全修订与对抗审查 | 验收: RFC覆盖cargo vendor override、fallback-resistant public config proof、manual-finalize状态机、fixed-forward边界且Round 7 review-rfc PASS
---

## 阶段 2: 实现与静态验证 ✅ COMPLETE

- [x] 在隔离 worktree 实现三台主机配置，完成构建、安全评审并合并配置 PR | 验收: 配置 PR #139 已合并为 `0026eb99`，不包含明文秘密
---

## 阶段 3: 生产部署 🔄 IN PROGRESS

- [ ] 从 clean merged baseline 依次 switch acorn、axiom、charlie并执行运行时验证 | 验收: Acorn已完成；Axiom runtime blocker已contained，须fixed-forward hotfix及fresh auth/finalize PASS后才可推进Charlie ← CURRENT
---

## 阶段 4: 证据收口 ⏳ NOT STARTED

- [ ] 提交部署证据、walkthrough 与 wiki writeback并完成 follow-up PR lifecycle | 验收: evidence PR 到达终态，blocking review 已处理，worktree 清理且主工作区刷新
---

## 发现的新任务

- [ ] Axiom-only runtime fixed-forward hotfix | 验收: direct canonical resolution、exact c1 Hyprland environment、PipeWire GStreamer factory、fresh revision state、正确密码画面/控制、错误密码负测和manual finalize全部PASS
---

*最后更新: 2026-07-13*
