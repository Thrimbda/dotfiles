# Aliyun Acorn ECS Deploy - 任务清单

## 快速恢复

**当前阶段**: 阶段 6 - Delivery
**当前检查项**: Complete PR lifecycle or record blocker
**进度**: 11/12 任务完成
---

## 阶段 1: Contract ✅ COMPLETE

- [x] Create stable Legion task contract | 验收: plan.md and tasks.md define goal, acceptance, assumptions, constraints, risks, scope, non-goals, and phases.
---

## 阶段 2: Research and Design ✅ COMPLETE

- [x] Research dotfiles image target and aliyun-ops operation method | 验收: docs/research.md cites relevant local files and identifies current constraints.
- [x] Produce deployment RFC | 验收: docs/rfc.md covers resource plan, command flow, rollback, and verification.
- [x] Review deployment RFC | 验收: docs/review-rfc.md passes or records required design changes.
---

## 阶段 3: Implementation ✅ COMPLETE

- [x] Enter git-worktree-pr envelope | 验收: production repository edits happen outside the shared main checkout.
- [x] Implement minimal deploy documentation or helper scripts | 验收: changes stay within approved scope and contain no secrets or large image artifacts.
---

## 阶段 4: Verification ✅ COMPLETE

- [x] Run local Nix and static verification | 验收: docs/test-report.md records pass/fail evidence and any builder/cloud blockers.
- [x] Run authorized Aliyun preflight or live deploy commands if confirmed | 验收: cloud-side command results or skipped-with-reason are recorded without secrets.
---

## 阶段 5: Review ✅ COMPLETE

- [x] Review implementation for scope, security, and operational risk | 验收: docs/review-change.md records pass/fail and residual risks.
---

## 阶段 6: Delivery 🟡 IN PROGRESS

- [x] Produce walkthrough and PR body | 验收: docs/report-walkthrough.md and docs/pr-body.md summarize reviewer-facing evidence.
- [x] Update Legion wiki | 验收: current truth and reusable Aliyun deployment patterns are written back.
- [ ] Complete PR lifecycle or record blocker | 验收: PR is merged/closed/blocked with worktree cleanup status documented. ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-06-16 03:32*
