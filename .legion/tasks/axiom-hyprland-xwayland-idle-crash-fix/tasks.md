# Axiom Hyprland XWayland Idle Crash Fix - 任务清单

## 快速恢复

**当前阶段**: 阶段 4 - Delivery
**当前检查项**: Review, document, and deliver the change through its PR lifecycle
**进度**: 3/4 任务完成
---

## 阶段 1: Design and RFC review ✅ COMPLETE

- [x] Choose and review the single-owner and socket-recovery strategy | 验收: The idle-owner boundary, reconnect behavior, rollback, and verification path are approved in the RFC review.
---

## 阶段 2: Implementation ✅ COMPLETE

- [x] Apply the Axiom idle-owner and watcher recovery changes | 验收: Only approved Axiom/config files change and the Caelestia/RustDesk/XWayland policy is preserved.
---

## 阶段 3: Verification ✅ COMPLETE

- [x] Run focused static and Nix checks | 验收: Evaluation proves one active idle owner and safe reconnect behavior; live smoke steps are recorded.
---

## 阶段 4: Delivery 🟡 IN PROGRESS

- [ ] Review, document, and deliver the change through its PR lifecycle | 验收: Review, walkthrough, wiki writeback, PR terminal state, cleanup, and baseline refresh are recorded. ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-19 04:22*
