# Restore 1Ex portfolio NAV sampling - 任务清单

## 快速恢复

**当前阶段**: 阶段 4 - Closeout
**当前检查项**: Run verification, security review, walkthrough, wiki writeback, and PR lifecycle cleanup.
**进度**: 4/5 任务完成
---

## 阶段 1: Design and review ✅ COMPLETE

- [x] Document the deployment and accounting safety design, then complete RFC review. | 验收: RFC identifies audience, deployment, accounting, rollback, and verification boundaries; review passes before operations.
- [x] Re-review the fresh adapter derivation strategy after Axiom store-state discovery. | 验收: Review confirms the version-only derivation identity change is safe, source-preserving, rollbackable, and required before deployment.
---

## 阶段 2: Deploy and verify source ✅ COMPLETE

- [x] Redeploy the current adapter closure from Axiom and verify the active binary plus custom-source positions path. | 验收: Live binary contains redirect_uri and the source returns complete positions without 502.
---

## 阶段 3: Initialize Fund units ✅ COMPLETE

- [x] Take a fresh Fund sample, create the approved owner baseline once, and immediately resample. | 验收: Fund has issued owner units, no duplicate event, fully priced sample, and a unit price derived from assets divided by units.
---

## 阶段 4: Closeout ⏳ NOT STARTED

- [ ] Run verification, security review, walkthrough, wiki writeback, and PR lifecycle cleanup. | 验收: Evidence is complete, PR reaches terminal state, worktree is removed, and main baseline is refreshed. ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-21 06:30*
