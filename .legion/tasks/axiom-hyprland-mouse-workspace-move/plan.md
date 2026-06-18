# Axiom Hyprland Mouse Workspace Move

## Task Identity

- Name: Axiom Hyprland Mouse Workspace Move
- Task ID: `axiom-hyprland-mouse-workspace-move`
- Risk: low-risk generated desktop keybind change

## 目标

Make Axiom Hyprland window movement more mouse-friendly by adding scoped compositor mouse bindings for moving/resizing windows and moving the active window to adjacent workspaces.

## 问题陈述

Axiom currently exposes keyboard-only workspace movement for windows. Hyprland and Caelestia can support mouse-driven workspace interactions, but the generated Axiom keybind set lacks native mouse window movement and mouse-wheel move-to-workspace bindings. Users need a minimal, discoverable workflow without changing Caelestia shell source or overlapping the separate second-monitor workspace task.

## 验收标准

- [ ] Generated Hyprland keybinds include SUPER + left mouse drag for moving windows.
- [ ] Generated Hyprland keybinds include SUPER + right mouse drag for resizing windows.
- [ ] Generated Hyprland keybinds include SUPER+SHIFT mouse wheel actions that move the active window to the previous or next relative workspace.
- [ ] The shortcut help text documents the new mouse window/workspace bindings.
- [ ] The task explicitly does not implement or modify axiom-second-monitor-workspaces, workspace 11..20 generation, or Caelestia upstream QML.
- [ ] Focused static validation covers generated keybind text and strongest available Nix/Hyprland config evidence.

## 假设 / 约束 / 风险

- **假设**: Hyprland 0.53-compatible classic config syntax supports bindm for mouse move/resize and bind mouse_up/mouse_down for wheel dispatchers.
- **假设**: SUPER+SHIFT+mouse wheel is not currently used by the generated Axiom keybind set.
- **假设**: Caelestia layer-shell UI may consume mouse events over its own surfaces, but does not change normal Hyprland dispatch semantics for ordinary windows.
- **假设**: Live graphical behavior validation may require the real Axiom Hyprland session and can be recorded as deferred if unavailable.
- **约束**: Do not touch or complete .legion/tasks/axiom-second-monitor-workspaces; another session owns it.
- **约束**: Keep the change in generated Axiom Hyprland config/help text unless validation proves a narrower adjustment is needed.
- **约束**: Do not modify Caelestia shell package source or Quickshell QML.
- **约束**: Do not redesign workspace numbering, monitor assignment, application placement rules, or existing keyboard bindings.
- **约束**: Keep Darwin unaffected.
- **风险**: Mouse wheel direction expectations can be inverted relative to user preference, so the implementation should document the chosen mapping clearly.
- **风险**: Hyprland parser syntax may differ slightly from examples; parser/static validation must catch this.
- **风险**: Layer-shell surfaces can still intercept mouse input when the pointer is over Caelestia UI, which is expected and out of scope.

## 要点

- Native Hyprland mouse binds are the correct layer for moving and resizing ordinary application windows.
- Caelestia remains relevant as shell UI, but this task does not add drag/drop behavior to Caelestia workspace widgets.
- The separate `axiom-second-monitor-workspaces` task remains owned by another session; this task must not change workspace 11..20 generation or second-monitor keybinds.
- The expected runtime caveat is that Caelestia layer-shell surfaces can still intercept mouse input over their own UI regions.

## 范围

- modules/desktop/hyprland.nix generated keybind block and keybinding help text
- .legion/tasks/axiom-hyprland-mouse-workspace-move/**
- .legion/wiki/** closeout entries

## Non-Goals / Out of Scope

- Do not implement or complete `axiom-second-monitor-workspaces`.
- Do not add workspace 11..20 generation, second-monitor shortcuts, or monitor assignment changes.
- Do not modify Caelestia shell source, Quickshell QML, or upstream shell packaging.
- Do not implement drag/drop of app windows or window icons onto Caelestia workspace widgets.
- Do not change existing keyboard workspace bindings, application placement rules, or workspace numbering.
- Do not perform live graphical validation unless a real Axiom Hyprland session is available.

## 设计索引 (Design Index)

> **Design Source of Truth**: （暂无）

**摘要**:
- Use Hyprland native mouse bind support instead of implementing drag/drop in Caelestia.
- Add a minimal compositor-level workflow: SUPER+left drag moves windows, SUPER+right drag resizes, SUPER+SHIFT+wheel moves the active window to adjacent workspaces.
- Treat Caelestia as shell UI that can expose its own window-info controls but is not modified by this task.
- Record the separate second-monitor workspace task as an explicit non-goal to avoid cross-session conflicts.

## 阶段概览

1. **Brainstorm** - Materialize focused mouse workspace movement contract and conflict boundary.
2. **Engineer** - Implement generated Hyprland mouse bindings and help text in an isolated worktree.
3. **Verify Change** - Run focused generated-config and static validation.
4. **Review Change** - Assess readiness and scope boundaries.
5. **Report Walkthrough** - Generate reviewer-facing summary and PR body.
6. **Legion Wiki** - Write task summary and reusable maintenance notes.

---

*创建于: 2026-06-18 | 最后更新: 2026-06-18*
