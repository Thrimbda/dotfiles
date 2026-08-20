# Axiom Hyprland Hotplug XWayland Crash Fix

## 目标

Prevent the observed Hyprland crash during monitor hotplug and XWayland floating-window mapping without removing XWayland or multi-monitor support.

## 问题陈述

Hyprland v0.56.1 crashed in CXWaylandSurface::map while Floating::newTarget ran near DP-4/DP-5 hotplug events. Safe mode recovered the session but disables the normal XWayland scaling behavior; the exact X11 client is unknown.

## 验收标准

- [x] A reviewed evidence-based design identifies a bounded mitigation rather than broadly disabling XWayland or monitor hotplug.
- [x] The Nix configuration or package override applies the selected mitigation while preserving the configured DP-4/DP-5 multi-monitor behavior.
- [x] Axiom configuration evaluation and the relevant Axiom build complete successfully with no new warnings attributable to this change.
- [x] Targeted static checks demonstrate the mitigation is present and the live session is not restarted or switched during validation.
- [x] The change is delivered through an isolated worktree and PR with rollback instructions.

## 假设 / 约束 / 风险

- **假设**: The preserved crash reports and journal timeline accurately represent the failure mode.
- **假设**: An upstream-compatible code or configuration mitigation can be selected without changing user applications.
- **约束**: Do not run nixos-rebuild switch, restart Hyprland/UWSM, trigger DPMS/hotplug, or otherwise disturb the preserved session.
- **约束**: Do not build or deploy on Acorn; preserve existing Axiom display, XWayland, and monitor-hotplug capabilities.
- **约束**: Use an isolated worktree and PR; do not modify the shared main worktree or its untracked credential files.
- **风险**: A static build cannot prove the timing-sensitive race is eliminated without a controlled later live-session test.
- **风险**: Changing Hyprland packaging may introduce compatibility or cache/build cost; a local patch must be narrowly scoped and reversible.
- **风险**: The NVIDIA VRAM exhaustion observed earlier may be an independent instability factor.

## 要点

- Evidence-based mitigation
- Minimal reversible scope
- No live-session disruption

## 范围

- modules/desktop/hyprland.nix and directly required Axiom desktop configuration
- A narrowly scoped Hyprland package override or patch only if supported by upstream evidence
- .legion/tasks/axiom-hyprland-hotplug-crash/** and required wiki/delivery evidence

## Non-goals

- Do not investigate or tune NVIDIA VRAM pressure, llama-server limits, or unrelated service failures in this task.
- Do not broadly upgrade flake inputs, disable XWayland, remove monitor-hotplug support, or change client applications.
- Do not restart, switch, or live-test the preserved desktop session without a separate explicit approval.

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-hyprland-hotplug-crash/docs/rfc.md

**摘要**:
- Use the crash stack and upstream source history to choose the smallest guard or version-level mitigation that prevents invalid floating placement during transient monitor loss.
- Validate via Nix evaluation/build plus focused assertions; defer any live switch or reproduction until the user explicitly accepts disruption.

## 阶段概览

1. **Contract and Design** - Record evidence, compare viable mitigations, and approve an RFC
2. **Isolated Implementation** - Implement the selected Nix/package mitigation in the worktree
3. **Verification and Review** - Run static, evaluation, and build validation and complete change review
4. **Delivery** - Create and follow the PR through its terminal lifecycle

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*
