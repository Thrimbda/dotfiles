# Aliyun Acorn Nix Cache Mirror - 任务清单

## 快速恢复

**当前阶段**: Delivery
**当前检查项**: 完成 Git lifecycle 或记录 blocker
**进度**: 9/10 任务完成

---

## 阶段 1: Contract ✅ COMPLETE

- [x] 创建稳定 Legion task contract | 验收: `plan.md` 覆盖目标、问题、验收、假设、约束、风险、范围和 non-goals。
- [x] 创建 design-lite | 验收: `docs/rfc.md` 说明方案、替代方案、回滚和验证。

---

## 阶段 2: Implementation ✅ COMPLETE

- [x] 打开 `git-worktree-pr` worktree | 验收: 分支 `legion/aliyun-acorn-nix-cache-mirror` 位于 `.worktrees/aliyun-acorn-nix-cache-mirror`。
- [x] 添加 host-level TUNA substituter | 验收: `hosts/aliyun-acorn/default.nix` 使用 `lib.mkBefore` prepend mirror。
- [x] 验证最终 substituter 顺序 | 验收: `nix eval` 输出 TUNA、Cachix、官方 cache 顺序。

---

## 阶段 3: Verification ✅ COMPLETE

- [x] 验证 `aliyun-acorn` toplevel 求值 | 验收: `nix eval '.#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath'` 成功。
- [x] 记录临时切换 cache 用法 | 验收: `docs/test-report.md` 或 walkthrough 包含 `--option substituters` 示例。

---

## 阶段 4: Review ✅ COMPLETE

- [x] 执行 change review | 验收: `docs/review-change.md` 记录 PASS/FAIL、范围和残余风险。

---

## 阶段 5: Delivery 🟡 IN PROGRESS

- [x] 生成 walkthrough 和 PR body | 验收: `docs/report-walkthrough.md` 与 `docs/pr-body.md` 可供 reviewer 使用。
- [x] 执行 wiki writeback | 验收: `.legion/wiki/**` 记录当前可复用知识或明确无需新增。
- [ ] 完成 Git lifecycle 或记录 blocker | 验收: commit/PR/checks/cleanup 状态记录在 `log.md`。 ← CURRENT

---

## 发现的新任务

(暂无)

---

*最后更新: 2026-06-20*
