# Axiom Nix Warning Migration - 任务清单

## 快速恢复

**当前阶段**: 阶段 3 - Validation and delivery
**当前检查项**: Rebase the reviewed branch on the latest origin/master, revalidate the integrated tree, and complete PR delivery.
**进度**: 2/3 任务完成
---

## 阶段 1: Inventory and design ✅ COMPLETE

- [x] Map every supplied warning to an active source and approve a behavior-preserving migration. | 验收: RFC records ownership, alternatives, rollback, and validation for platform and power-management changes.
---

## 阶段 2: Migration ✅ COMPLETE

- [x] Apply the smallest source-level deprecation and alias migrations. | 验收: All changed references use supported NixOS, Home Manager, and Nixpkgs forms.
---

## 阶段 3: Validation and delivery ⏳ IN PROGRESS

- [x] Rebuild and validate Axiom. | 验收: The exact build output is warning-free, the Bluetooth VM regression passes, and shared Colemak consumers retain XKB and SSH askpass behavior.
- [x] Complete independent change review. | 验收: `docs/review-change.md` records a PASS decision with no blocking findings.
- [ ] Rebase, revalidate, and deliver through the PR lifecycle. | 验收: Walkthrough, wiki, PR, merge, cleanup, and main-worktree refresh evidence is complete. ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-20 06:43*
