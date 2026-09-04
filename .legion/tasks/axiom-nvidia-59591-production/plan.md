# Axiom NVIDIA latest production driver (595.99.02)

## 目标

Upgrade Axiom RTX 5090 from the beta NVIDIA driver to NVIDIA production driver 595.99.02 without a whole-system Nixpkgs upgrade.

## 问题陈述

The shared NVIDIA profile pins nvidiaPackages.beta. The pinned NixOS 26.05 package set exposes production 595.71.05, which does not meet the requested latest production release 595.99.02.

## 验收标准

- [x] The declarative configuration selects NVIDIA production driver 595.99.02 for the Axiom current kernel package set.
- [x] The change preserves open kernel modules, Wayland modesetting, power management, CUDA settings, and existing non-Axiom hosts.
- [x] The Axiom NixOS configuration evaluates and rebuilds successfully.
- [x] After reboot, nvidia-smi reports driver 595.99.02 and the RTX 5090 remains bound to the nvidia kernel driver.
- [x] Rollback instructions and review evidence are recorded.

## 假设 / 约束 / 风险

- **假设**: Axiom is the target host and its RTX 5090 supports NVIDIA open kernel modules.
- **假设**: The upstream production-release hashes documented by Nixpkgs are valid for the selected driver.
- **约束**: Use NixOS declarative configuration; do not use NVIDIA .run installers.
- **约束**: Do not update the entire Nixpkgs baseline solely for this driver update.
- **约束**: Do not modify or build Acorn.
- **约束**: Activation must run locally on Axiom and requires a reboot.
- **风险**: A graphics-driver change can interrupt the active Hyprland session or fail during reboot.
- **风险**: A manually pinned production driver must be updated deliberately for future security releases.
- **风险**: A source-hash or kernel-module compatibility issue can block the rebuild.

## 要点

- Use config.boot.kernelPackages.nvidiaPackages.mkDriver to keep the module compatible with the Axiom configured kernel.
- Keep hardware.nvidia.open = true and the existing NVIDIA integration unchanged.
- Provide a rollback path to the previous beta selector.

## 范围

- Set hardware.nvidia.package to a reproducible 595.99.02 production derivation compatible with config.boot.kernelPackages.
- Retain current hardware.nvidia.open, modesetting, power management, and CUDA settings.
- Deploy only Axiom through the declarative NixOS path and reboot to activate.
- Out of scope: changing Acorn, using NVIDIA .run installer, or upgrading the entire Nixpkgs baseline.

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- Use the existing kernel package set mkDriver helper with the upstream 595.99.02 production-release hashes, rather than switching to a beta package or changing the system-wide Nixpkgs input.
- Validate the configuration before activation, then verify the loaded driver and kernel binding after reboot.
- Rollback restores config.boot.kernelPackages.nvidiaPackages.beta and redeploys the prior configuration.

## 阶段概览

1. **Design and review** - Write and approve the safe driver-upgrade RFC.
2. **Implementation and deployment** - Pin NVIDIA 595.99.02 and activate the Axiom configuration.
3. **Verification and delivery** - Verify the loaded driver after reboot and complete delivery review.

---

*创建于: 2026-09-04 | 最后更新: 2026-09-04*
