# Axiom RustDesk Provision Recovery

## 目标

Make Axiom RustDesk permanent-password provisioning safely recover after an interrupted attempt so nixos-rebuild does not remain blocked.

## 问题陈述

The provisioner writes a revision-matched attempt marker before setting the password. A later failure leaves that marker behind, and every subsequent activation exits with attempt-used instead of distinguishing an incomplete attempt from completed state.

## 验收标准

- [ ] A valid current attempt marker with no ready-to-finalize marker is safely cleared and provisioning retries on a later activation.
- [ ] A valid current attempt marker paired with a valid current ready-to-finalize marker exits successfully without resetting the password or bypassing manual remote-auth finalization.
- [ ] Malformed, symlinked, or ownership-invalid attempt or ready state reached by recovery remains a hard failure; the current stamp fast path remains unchanged.
- [ ] The generated Axiom configuration and focused static checks verify the recovery branches and no longer contain the terminal attempt-used path.

## 假设 / 约束 / 风险

- **假设**: Retrying RustDesk with the same agenix-provided permanent password is an acceptable idempotent recovery operation.
- **假设**: The existing ready-to-finalize record is evidence of a successful password application that still awaits separate remote-auth confirmation.
- **约束**: Keep the permanent password root-only and do not emit secret values or paths in logs.
- **约束**: Preserve lock acquisition, state ownership checks, runtime verification, and the explicit rustdesk-provision-finalize confirmation gate.
- **约束**: Make all source and task-document changes only in the isolated worktree; do not include main-worktree untracked credential files.
- **风险**: A retry can reissue the password command after an uncertain partial run, so cleanup must be limited to validated state and use the configured secret only.
- **风险**: Incorrectly treating a ready marker as final completion could bypass the remote-auth confirmation workflow.
- **风险**: Runtime readiness may still fail for independent RustDesk or session reasons; those failures must remain visible rather than being converted to success.

## 要点

- Idempotent recovery for interrupted attempts
- Fail closed for untrusted state
- Preserve manual finalization boundary

## 范围

- hosts/axiom/modules/rustdesk.nix
- .legion/tasks/axiom-rustdesk-provision-recovery/**
- Required Legion wiki and delivery evidence

## Non-goals

- Do not change the RustDesk server topology, client version, portal capture behavior, or remote-access policy.
- Do not remove the explicit remote-auth confirmation required to finalize a provisioned password.
- Do not convert malformed or contradictory persistent state into a successful activation.
- Do not expose, rotate, or change the encrypted permanent password in this task.

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-rustdesk-provision-recovery/docs/rfc.md

**摘要**:
- Reset only a validated in-progress attempt when no successful ready record exists, then run the existing provisioning sequence.
- Treat a validated current ready record as successful pending manual finalization, not as a reason to rerun password provisioning.
- Keep invalid or contradictory state reached by recovery fail-closed and verify both recovery paths before deployment.

## 阶段概览

1. **Contract and Recovery Design** - Write and review the recovery RFC
2. **Isolated Implementation** - Implement validated attempt recovery in the Axiom provisioner
3. **Verification and Review** - Evaluate the configuration and review the recovery change
4. **PR Delivery** - Deliver and follow the PR to a terminal state

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*
