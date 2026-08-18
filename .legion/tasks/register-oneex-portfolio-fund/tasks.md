# Register private 1Ex portfolio Fund - 任务清单

## 快速恢复

**当前阶段**: 完成
**当前检查项**: 所有阶段已完成；后续仅按 maintenance 项监控 source 与 hourly NAV sampling
**进度**: 5/5 任务完成
---

## 阶段 1: Design and preflight ✅ COMPLETE

- [x] Inspect current sources and Funds, fix source/Fund identity, and record rollback | 验收: No existing source or Fund is changed during preflight; the target ID, owner boundary, and rollback path are explicit.
---

## 阶段 2: Confirm recursion exclusion ✅ COMPLETE

- [x] Confirm the deployed EXCLUDED_FUND_ID is unused and reserve it as the Fund ID | 验收: No Acorn configuration change is needed; post-creation validation will prove the Fund is excluded from direct adapter positions.
---

## 阶段 3: Register and validate account source ✅ COMPLETE

- [x] Create or reconcile the enabled 1Ex Custom Account Source | 验收: Unified 1Ex discovery exposes the adapter AccountID and the same stable product and position IDs as a direct adapter read.
---

## 阶段 4: Create and validate private Fund ✅ COMPLETE

- [x] Create and sample the private USD My Portfolio Fund | 验收: The Fund is private, non-subscribable, bound to the source account, and absent from direct adapter positions.
---

## 阶段 5: Review and delivery ✅ COMPLETE

- [x] Record verification, review, wiki, and PR lifecycle evidence | 验收: The external mutations and code/config change are reviewed, merged or explicitly blocked, and rollback state is recorded. PR #163 merged; no required checks or review gate were configured.
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-18 15:58*
