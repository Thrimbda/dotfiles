# Dotfiles Hyprland Conf to Lua Migration - 任务清单

## 快速恢复

**当前阶段**: done (PR #167 merged; wiki closeout PR pending)
**当前检查项**: (none)
**进度**: 8/8 任务完成
---

## 阶段 1: Brainstorm ✅ COMPLETE

- [x] Materialize the hyprland conf-to-lua migration contract. | 验收: plan.md and tasks.md define goal, acceptance, scope, non-goals, assumptions, risks, and the recommended hl.* migration path; task directory exists under .legion/tasks/dotfiles-hyprland-lua-migration.
---

## 阶段 2: Spec RFC ✅ COMPLETE

- [x] Write docs/rfc.md with the hyprlang->Lua mapping table, file-by-file conversion sketch, verification strategy, and rollback plan. | 验收: docs/rfc.md contains Options + Decision + Verification and plan.md design index links to it.
---

## 阶段 3: Review RFC ✅ COMPLETE

- [x] Run adversarial review-rfc against the design and converge to PASS. | 验收: docs/review-rfc.md records PASS; axiom extraConfig gap folded back into rfc.md before implementation.
---

## 阶段 4: Engineer ✅ COMPLETE

- [x] Implement the migration in an isolated worktree: root hyprland.lua, generated .lua configFile entries, extraConfig conversions for axiom/azar/ramen/udon/autumnal. | 验收: Diff contains only scoped changes; no hyprland .conf remains in the config path; hypridle.conf untouched.
---

## 阶段 5: Verify Change ✅ COMPLETE

- [x] Render generated files, run luac syntax checks, build the axiom closure, record evidence. | 验收: docs/test-report.md records rendered-file inspection, syntax results, and axiom build result.
---

## 阶段 6: Review Change ✅ COMPLETE

- [x] Assess whether the change is ready for delivery and matches the approved design. | 验收: docs/review-change.md records PASS with scope-boundary confirmation.
---

## 阶段 7: Report Walkthrough ✅ COMPLETE

- [x] Produce reviewer-facing delivery summary and PR body. | 验收: docs/report-walkthrough.md and docs/pr-body.md describe behavior, files, verification, and deploy steps.
---

## 阶段 8: Legion Wiki ✅ COMPLETE

- [x] Write task summary, decisions, and maintenance notes into .legion/wiki. | 验收: .legion/wiki index and decisions capture the lua migration decision and post-merge deploy notes.
---

## 发现的新任务

- Post-merge live deploy smoke on axiom: `nixos-rebuild switch --flake .#axiom` + `hey reload`, confirm warning gone, startup hook order, keybind spot checks (see docs/test-report.md residual list).
---

*最后更新: 2026-08-19*
