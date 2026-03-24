# acorn 新配置适配与构建修复 - 任务清单

## 快速恢复

**当前阶段**: (unknown)
**当前任务**: (none)
**进度**: 6/6 任务完成

---

## 阶段 1: 阶段 1 - 设计与现状确认 🟡 IN PROGRESS

- [x] 审阅 acorn 与 vaultwarden 相关配置及当前 .legion 状态，确认问题边界与验证入口 | 验收: plan.md 完成并记录风险分级、允许 Scope、验证策略
- [x] 执行 design-lite 或 RFC 决策并形成设计索引 | 验收: plan.md 的 Design Index 可指向 design-lite 或 docs/rfc.md

---

## 阶段 2: 阶段 2 - 实现与构建修复 🟡 IN PROGRESS

- [x] 按设计修改 acorn 配置及最小必要共享模块 | 验收: 修改保持在允许 Scope 内，并在 context.md 记录关键决策
- [x] 运行 nix build 验证并修复阻塞 | 验收: 能在当前环境完成最大化验证；不可验证部分有明确假设

---

## 阶段 3: 阶段 3 - 验证与交付文档 🟡 IN PROGRESS

- [x] 产出测试/评审报告 | 验收: docs/test-report.md 与 docs/review-code.md 生成；必要时包含 review-security.md
- [x] 生成 walkthrough 与 PR body | 验收: docs/report-walkthrough.md 与 docs/pr-body.md 可直接用于交付

---

## 发现的新任务

(暂无)
- [ ] 排查并修复 acorn 上 vaultwarden-env age secret 未落盘导致的 vaultwarden 启动失败 | 来源: 用户反馈 vaultwarden.service 缺少 environmentFile


---

*最后更新: 2026-03-24 22:14*
