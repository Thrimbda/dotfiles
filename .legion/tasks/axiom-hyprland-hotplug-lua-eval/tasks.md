# Axiom Hyprland Hotplug Lua Eval Compatibility - 任务清单

## 快速恢复

**当前阶段**: (none)
**当前检查项**: (none)
**进度**: 4/4 任务完成
---

## 阶段 1: Contract and Design ✅ COMPLETE

- [x] Record the low-risk compatibility design and rollback boundary | 验收: The task contract and design-lite explain why eval replaces keyword and define validation limits.
---

## 阶段 2: Implementation ✅ COMPLETE

- [x] Replace the legacy monitor command with a Lua eval expression | 验收: The generated reconciler retains monitor values and no longer invokes the unsupported keyword interface.
---

## 阶段 3: Verification and Review ✅ COMPLETE

- [x] Validate generated behavior, Nix build results, and change scope | 验收: Evidence shows the expression is valid, the target configuration builds, and review finds no blocking regression.
---

## 阶段 4: Delivery ✅ COMPLETE

- [x] Deliver the fix through PR lifecycle and document runtime smoke steps | 验收: PR #189 merged, the source delivery records rollback and the deferred post-deployment monitor smoke, and this closeout completes the task lifecycle.
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-21 15:14*
