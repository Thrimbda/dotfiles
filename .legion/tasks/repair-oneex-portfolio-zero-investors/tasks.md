# Repair My Portfolio zero-investor NAV - 任务清单

## 快速恢复

**当前阶段**: 阶段 4 - Verify and close
**当前检查项**: Verify the repaired Fund, perform security/change review, publish walkthrough and wiki evidence, and complete PR lifecycle cleanup.
**进度**: 3/4 任务完成
---

## 阶段 1: Design and review ✅ COMPLETE

- [x] Document the accounting-repair design and pass high-risk RFC review. | 验收: The approved design identifies exact event-selection, delete order, stop conditions, subscription lock, verification, and rollback boundaries.
---

## 阶段 2: Live preflight ✅ COMPLETE

- [x] Capture a redacted live snapshot of Fund configuration, statement, source health, NAV, and event indexes. | 验收: The two erroneous initialization events and expected post-repair invariants are proven without a mutation.
---

## 阶段 3: Apply bounded repair ✅ COMPLETE

- [x] Delete only the approved initial cash-flow and owner-profile events, preserve Fund configuration with subscriptions closed, and take one fresh sample. | 验收: The event stream stays reducible, no new accounting event is created, and the Fund has one-source assets with no investor or share.
---

## 阶段 4: Verify and close ⏳ IN PROGRESS

- [ ] Verify the repaired Fund, perform security/change review, publish walkthrough and wiki evidence, and complete PR lifecycle cleanup. | 验收: Evidence proves zero investors, zero shares, closed subscriptions, single-count assets, terminal PR state, worktree removal, and refreshed main baseline. ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-21 15:30*
