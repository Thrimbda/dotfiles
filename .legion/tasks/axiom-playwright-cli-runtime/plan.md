# Axiom Playwright CLI Runtime

## 目标

Make Playwright CLI available system-wide on the Axiom NixOS host with the browser/runtime dependencies needed for local browser automation.

## 问题陈述

Axiom should be able to run Playwright-based browser automation from the system environment without mutating individual project dependency files or relying on ad hoc npm downloads.

## 验收标准

- [ ] Axiom declarative configuration installs a system-level Playwright CLI entrypoint or equivalent package-provided CLI.
- [ ] Axiom configuration also provides the related browser/runtime dependency surface needed by Playwright under NixOS.
- [ ] No project-level npm/pnpm/yarn dependency files are modified.
- [ ] No live nixos-rebuild switch is performed as part of this task.
- [ ] Verification records Nix evaluation/build evidence or documents any package/runtime blocker.

## 假设 / 约束 / 风险

- **假设**: The target host is hosts/axiom/default.nix and the package should be host-local unless validation proves a reusable module is required.
- **假设**: The intended use is local browser automation by user c1 or agent tooling from Axiom, not application deployment.
- **假设**: Pinned nixpkgs contains a usable Playwright package or browser-driver package for x86_64-linux.
- **约束**: Follow Legion workflow and git-worktree-pr delivery for implementation changes.
- **约束**: Preserve unrelated user or agent changes in the main checkout.
- **约束**: Keep the change declarative; do not run mutable Playwright browser download/install flows in the repository.
- **风险**: Playwright packaging in nixpkgs may require specific environment variables or browser package integration beyond simply adding a CLI package.
- **风险**: Nix build/eval can validate package presence, but live browser launch may still require an Axiom session smoke test after deployment.

## 要点

- Prefer the existing Axiom host-local user.packages pattern for one-off host tooling.
- Treat browser/runtime integration as part of the package dependency surface, not a project devDependency change.
- Keep live switch and runtime profile state outside this task unless explicitly requested later.

## 范围

- Update Axiom declarative host configuration for Playwright CLI/runtime availability.
- Add or update Legion task artifacts for plan, tasks, verification, review, walkthrough, and wiki writeback.
- Validate the Axiom configuration using the most credible local Nix checks available.

## 非目标

- Do not modify project-level npm, pnpm, yarn, or application dependency files.
- Do not run mutable Playwright browser download/install flows as repository state.
- Do not change other hosts or introduce a reusable module unless validation proves host-local configuration is insufficient.
- Do not perform a live `nixos-rebuild switch`; deployment and runtime browser smoke remain post-merge/post-switch work.

## 设计索引 (Design Index)

> **Design Source of Truth**: No RFC expected unless package validation reveals cross-module or runtime-policy uncertainty.

**摘要**:
- Use a minimal host-local Nix change first: install the Playwright CLI/runtime packages in Axiom configuration.
- If nixpkgs requires environment variables such as browser path wiring, add only the narrow host-level integration needed for system CLI usability.
- Do not add project dependency files, mutable browser downloads, account/profile setup, or live system activation.

## 阶段概览

1. **Contract Materialization** - Create and review the Legion task contract.
2. **Implementation** - Update Axiom configuration for Playwright CLI/runtime availability.
3. **Verification** - Validate package availability and Axiom configuration shape.
4. **Review And Handoff** - Review readiness, write walkthrough, and update Legion wiki.

---

*创建于: 2026-05-13 | 最后更新: 2026-05-13*
