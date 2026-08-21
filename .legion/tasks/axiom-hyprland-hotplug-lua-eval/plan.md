# Axiom Hyprland Hotplug Lua Eval Compatibility

## 目标

Replace the legacy monitor-hotplug runtime command with the Lua-compatible Hyprland command while preserving Axiom monitor behavior and the existing XWayland crash guard.

## 问题陈述

The monitor hotplug reconciler calls hyprctl keyword monitor even though Axiom uses hyprland.lua. Hyprland rejects that legacy parser command with keyword cannot work with non-legacy parsers. Use eval.

## 验收标准

- [x] The generated reconciler invokes hyprctl eval with a valid hl.monitor call instead of hyprctl keyword monitor.
- [x] The runtime expression preserves the existing output, mode, position, and scale selected by reconciliation logic.
- [x] Targeted static and Nix build validation pass without changing keyboard, Fcitx, monitor inventory, or the XWayland crash guard.
- [x] Delivery records rollback and a post-deployment monitor hotplug smoke test.

## 假设 / 约束 / 风险

- **假设**: The journal error from hyprland-monitor-hotplug is the source of the reported red overlay.
- **假设**: The current physical keyboard test output arst confirms Colemak is functioning and needs no source change.
- **约束**: Only change the monitor-hotplug Lua compatibility path and required task, review, and delivery evidence.
- **约束**: Do not modify the existing Hyprland package patch, keyboard or Fcitx configuration, monitor inventory, or session target lifecycle.
- **约束**: Use an isolated worktree and PR. Do not switch or restart the current Axiom session during source validation.
- **风险**: An invalid generated Lua expression could prevent monitor reconciliation after deployment.
- **风险**: Static validation cannot prove monitor power-cycle timing behavior; a later post-deployment smoke test remains required.

## 要点

- Low-risk, reversible local compatibility fix.
- Preserve current monitor selection and only replace the rejected parser entry point.

## 范围

- modules/desktop/hyprland.nix
- .legion/tasks/axiom-hyprland-hotplug-lua-eval/**
- Required wiki and PR delivery evidence

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-hyprland-hotplug-lua-eval/docs/rfc.md

**摘要**:
- Generate a Lua hl.monitor expression from the same reconciled monitor values and execute it through hyprctl eval.
- Quote runtime strings safely and preserve numeric scale handling.
- Validate the generated helper and Axiom configuration before deferring live monitor testing to deployment.

## 阶段概览

1. **Contract and Design** - Record the low-risk compatibility design and rollback boundary
2. **Implementation** - Replace the legacy monitor command with a Lua eval expression
3. **Verification and Review** - Validate generated behavior, Nix build results, and change scope
4. **Delivery** - Deliver the fix through PR lifecycle and document runtime smoke steps

---

*创建于: 2026-08-21 | 最后更新: 2026-08-21*
