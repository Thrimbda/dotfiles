# Install ToDesk on axiom

## 目标

Make ToDesk available on the axiom NixOS host through the dotfiles configuration.

## 问题陈述

axiom currently does not declare ToDesk, so the remote desktop client is not installed by the host configuration.

## 验收标准

- [ ] hosts/axiom/default.nix declares pkgs.todesk for the axiom user package set.
- [ ] The change stays scoped to axiom and does not enable a ToDesk daemon or system switch.
- [ ] Nix evaluation confirms the pinned nixpkgs set exposes an unbroken x86_64-linux todesk package.
- [ ] A credible host configuration validation is attempted and recorded.

## 假设 / 约束 / 风险

- **假设**: The intended install method is declarative Nix config, not ad-hoc installation on the live machine.
- **假设**: ToDesk only needs to be available as an application package for the c1 user.
- **假设**: The pinned nixpkgs package pkgs.todesk is acceptable for this task.
- **约束**: Do not run nixos-rebuild switch in this session.
- **约束**: Do not touch unrelated axiom services or existing remote access configuration.
- **约束**: Preserve unrelated user work in the dirty main worktree.
- **风险**: ToDesk is proprietary/unfree and may have runtime requirements not caught by evaluation.
- **风险**: Local main-worktree edits already touch hosts/axiom/default.nix, so this branch must avoid folding those unrelated edits into the task.

## 要点

- Add pkgs.todesk to axiom user.packages.
- Validate package metadata and host configuration as far as feasible without switching the system.
- Record verification and delivery evidence under the task.

## 范围

- hosts/axiom/default.nix
- .legion/tasks/axiom-install-todesk

## 非目标 / Out of Scope

- Do not enable or manage a ToDesk daemon/service in this task.
- Do not run `nixos-rebuild switch` or make live-system changes in this session.
- Do not modify unrelated axiom remote-access services, firewall rules, or desktop modules.
- Do not fold existing dirty main-worktree edits into this PR unless they are independently requested.

## 设计索引 (Design Index)

> **Design Source of Truth**: （暂无）

**摘要**:
- Use the existing host-local user.packages list instead of adding a reusable desktop app module because the request is host-specific and low risk.
- Avoid enabling any ToDesk service automatically; package installation is sufficient unless a future task asks for daemon/session integration.

## 阶段概览

1. **contract** - Confirm minimal declarative install scope
2. **implementation** - Add ToDesk to axiom packages
3. **verification** - Validate package metadata and host configuration
4. **delivery** - Produce review, walkthrough, and wiki writeback

---

*创建于: 2026-05-11 | 最后更新: 2026-05-11*
