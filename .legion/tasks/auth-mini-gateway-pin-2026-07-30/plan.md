# Auth Mini Gateway Pin 2026-07-30

## 目标

Make the declarative dotfiles pin match the latest upstream auth-mini-gateway already running on Acorn.

## 问题陈述

Dotfiles master pins Thrimbda/auth-mini-gateway@28a4a27 (2026-07-16) while Acorn's deployed closure runs 0.1.0-unstable-2026-07-30 built from upstream master e1ea3e7 (audience-bound login #16 + docs #17). Any future rebuild from master silently reverts the gateway to the old revision.

## 验收标准

- [ ] packages/auth-mini-gateway/default.nix pins rev e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4 with version 0.1.0-unstable-2026-07-30 and correct fixed-output hashes.
- [ ] The auth-mini-gateway package builds successfully on Axiom.
- [ ] Gateway service, instance, secret, nginx, and port configuration remain unchanged.
- [ ] The change is merged through a PR and the main workspace is refreshed.

## 假设 / 约束 / 风险

- **假设**: Acorn's running gateway binary was verified byte-identical (same store path q62fpw730jv2c6hwh1swnysh5ih434bl) to an Axiom build of upstream e1ea3e7, so no Acorn redeploy is required after merge.
- **假设**: Upstream cargo dependencies did not change; the existing cargoHash still builds (already proven by the local verification build).
- **约束**: Update only packages/auth-mini-gateway/default.nix plus Legion delivery evidence.
- **约束**: Preserve buildRustPackage and exact-revision source pinning.
- **约束**: Do not expose gateway secrets or session data.
- **风险**: A wrong source hash would break evaluation; the hash sha256-gkaFhFbPk/oyyYrnOJzeRs0oexMQTMH7y5Ci3exqPxk= was already verified by a successful local build at e1ea3e7.

## 要点

- Runtime already verified at latest; this task only aligns the declarative pin.

## 范围

- packages/auth-mini-gateway/default.nix

## 非目标 (Non-Goals)

- 不重新部署或 switch Acorn（运行时已验证为最新，仅对齐声明式 pin）。
- 不修改 gateway service、实例、secret、nginx 或端口配置。
- 不引入 RFC 或重新设计部署方式。

## 设计索引 (Design Index)

> **Design Source of Truth**: （暂无）

**摘要**:
- 核心流程: 更新 rev/version/src hash,cargoHash 保持不变。
- 验证策略: Axiom 本机构建 package,并确认产出 store path 与 Acorn 运行中的一致。

## 阶段概览

1. **Update pin** - Update rev, version, and src hash in packages/auth-mini-gateway/default.nix in a worktree
2. **Verify** - Build the package on Axiom and confirm the output store path matches Acorn's deployed path
3. **Deliver** - Open PR, merge, clean up worktree, refresh main workspace, write back to legion wiki

---

*创建于: 2026-07-31 | 最后更新: 2026-07-31*
