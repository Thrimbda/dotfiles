# Axiom Nix Warning Migration

## 目标

Eliminate every deterministic, repository-owned evaluation and system-path warning from the Axiom NixOS build by migrating deprecated options, package aliases, obsolete platform declarations, and duplicate package ownership without changing intended desktop behavior.

## 问题陈述

The Axiom system build emits deprecated Home Manager defaults, renamed packages and options, a deprecated power-management hook, an obsolete x86_64-darwin platform declaration, and duplicate binaries in the system path. The build can also report transient cache TLS retries and an upstream Gawk info-dir defect, neither of which is a repository configuration warning.

## 验收标准

- [ ] nixos-rebuild build --flake .#axiom succeeds with no evaluation warnings from the supplied baseline.
- [ ] GTK4 uses the explicitly selected null theme default while GTK3 Thunar styling, GTK icon/cursor configuration, and dark preference remain intact.
- [ ] Every package and option warning is migrated to its supported equivalent without global warning suppression.
- [ ] The flake only evaluates platforms that remain intentionally supported, and no existing host loses support unintentionally.
- [ ] The generated system path has no repository-owned binary or data-path collision warnings.
- [ ] Linux system Info documentation is disabled by explicit user choice, so the Gawk Info direntry warning is absent.

## 假设 / 约束 / 风险

- **假设**: The pasted diagnostics came from the current Axiom configuration path.
- **假设**: There is no active x86_64-darwin host unless repository metadata proves otherwise.
- **假设**: Equivalent package and option migrations preserve runtime behavior.
- **约束**: Do not deploy the resulting configuration.
- **约束**: Do not build or deploy Acorn.
- **约束**: Do not update Nixpkgs merely to hide warnings.
- **约束**: Keep the change limited to warning sources reachable from the Axiom build.
- **约束**: Do not remove system documentation, cache substituters, or application functionality solely to hide an upstream or transient diagnostic.
- **风险**: Removing x86_64-darwin from the flake may affect an unregistered Darwin consumer.
- **风险**: Replacing powerManagement.powerUpCommands requires an explicit service ordering that preserves wake behavior.
- **风险**: Switching GTK4 to null changes the default theme inheritance for future GTK4 applications by explicit user choice.
- **风险**: Resolving system-path collisions requires preserving the wrapped SSH, Steam, and NVIDIA behavior while assigning each binary a single owner.
- **风险**: System Info pages are unavailable by default, matching the repository's existing disabled-documentation posture.

## 要点

- Exact warning inventory
- Supported NixOS and package migrations
- Explicit GTK4 policy
- Warning-free rebuild

## 范围

- flake platform declarations and host metadata needed for x86_64-darwin
- Axiom-reachable NixOS and Home Manager options
- Package references, system-path ownership, and power wake test behavior that emit supplied warnings
- Task evidence and delivery artifacts

## 非目标

- Do not suppress diagnostics globally or change Nixpkgs only to hide them.
- Do not change cache configuration to hide transient TLS retry messages.
- Do not alter production Bluetooth resume behavior; only its focused VM test fixture changes.

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-nix-warning-migration/docs/rfc.md

**摘要**:
- Replace each deprecated reference with its documented equivalent rather than filtering output.
- Remove x86_64-darwin only after confirming no declared host targets it.
- Model the deprecated wake command as an ordered oneshot service and verify the generated unit before rebuilding.
- Give each system-path binary one intentional package owner instead of resolving collisions through broad priority suppression.
- Disable Linux Info documentation by explicit user choice rather than carrying an upstream Gawk patch.

## 阶段概览

1. **Inventory and design** - Map every supplied warning to an active source and approve a behavior-preserving migration.
2. **Migration** - Apply the smallest source-level deprecation and alias migrations.
3. **Validation and delivery** - Rebuild Axiom, review the change, and deliver it through the PR lifecycle.

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*
