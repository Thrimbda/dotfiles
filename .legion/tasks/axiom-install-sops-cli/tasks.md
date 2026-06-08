# Axiom Install Sops CLI - 任务清单

## 快速恢复

**当前阶段**: Git / PR Lifecycle
**当前检查项**: Commit, rebase, push, open PR, and follow checks/review
**进度**: 4/4 任务完成

---

## 阶段 1: Contract Materialization ✅ COMPLETE

- [x] 创建并回读 Legion task contract。 | 验收: `plan.md` 和 `tasks.md` 捕获目标、验收、范围、假设、约束、风险、非目标和阶段。

---

## 阶段 2: Implementation ✅ COMPLETE

- [x] Add `sops` to Axiom user packages. | 验收: `hosts/axiom/default.nix` 使用现有 host-local `user.packages` 模式安装 `pkgs.sops`。

---

## 阶段 3: Verification ✅ COMPLETE

- [x] Validate Axiom Nix configuration. | 验收: Nix eval/build 证据写入 `docs/test-report.md`，或环境阻塞被明确记录。

---

## 阶段 4: Review And Handoff ✅ COMPLETE

- [x] Review readiness, write walkthrough, and update Legion wiki. | 验收: `docs/review-change.md`、`docs/report-walkthrough.md`、`docs/pr-body.md` 与 wiki writeback 记录 scope、验证和残余风险。

---

## 发现的新任务

- [ ] 若需要 declarative secrets integration，另建 `sops-nix` 设计任务评估 agenix 共存/迁移。

---

*最后更新: 2026-06-08 00:00*
