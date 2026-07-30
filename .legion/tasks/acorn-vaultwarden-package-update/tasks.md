# Acorn Vaultwarden Package Update - 任务清单

## 快速恢复

**当前阶段**: 阶段 5 - Review and Delivery
**当前检查项**: Complete PR lifecycle, cleanup, and main workspace refresh
**进度**: 13/14 任务完成
---

## 阶段 1: Contract ✅ COMPLETE

- [x] Materialize the stable update contract | 验收: plan.md and tasks.md record scope, non-goals, acceptance, constraints, risks, and phases.
---

## 阶段 2: Design ✅ COMPLETE

- [x] Produce a focused Vaultwarden package-update RFC | 验收: RFC defines package source, version verification, backup preflight, deployment, health checks, and rollback.
- [x] Review the RFC | 验收: Review PASS confirms the isolated-input design and operational safeguards before implementation.
- [x] Revise the RFC for the auth-mini fixed-output pin repair | 验收: RFC defines authoritative asset provenance, mutable-tag fail-closed behavior, package-only scope, auth service health checks, rollback, and deployment restart conditions.
- [x] Review the revised auth-mini RFC | 验收: Review PASS confirms the security-sensitive package repair is minimal, evidence-backed, and safe to implement.
---

## 阶段 3: Implementation ✅ COMPLETE

- [x] Create an isolated worktree and implement the approved input override | 验收: Only intended flake and Acorn Vaultwarden configuration changes are made in the worktree.
- [x] Repair the reviewed auth-mini version metadata and fixed-output SHA | 验收: Only packages/auth-mini/default.nix changes; the reviewed asset-ID source, header, metadata, and hash are updated while services, secrets, data, and routing stay untouched.
---

## 阶段 4: Verification ✅ COMPLETE

- [x] Verify lock isolation, configuration, package version, and deployment readiness | 验收: Evidence records the updated package version and confirms the primary nixpkgs lock remains unchanged.
- [x] Deploy from Axiom and validate Vaultwarden health | 验收: The prescribed remote deployment succeeds and service health is checked, or a blocker is recorded without building on Acorn.
- [x] Re-run the Axiom deployment and verify Vaultwarden and auth-mini health | 验收: After a fresh backup, the prescribed Axiom command succeeds and both services have verified non-sensitive health evidence.
---

## 阶段 5: Review and Delivery 🟡 IN PROGRESS

- [x] Review implementation and operational safety | 验收: Review records pass or concrete remediation items.
- [x] Produce delivery artifacts and write back the Legion wiki | 验收: Walkthrough, PR body, and reusable operational knowledge are recorded.
- [x] Record residual-risk review and explicit version-control disposition | 验收: User accepts or keeps open the recorded residual risks, and any commit or PR action is explicitly authorized or intentionally deferred.
- [ ] Complete PR lifecycle, cleanup, and main workspace refresh | 验收: The PR is merged after checks, the task worktree is removed, and the main workspace is fast-forward refreshed without touching unrelated files. ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-07-30 06:09*
