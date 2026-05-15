# Foot Tmux Hotkey

## 目标

让 Hyprland 的 SUPER+SHIFT+Enter 打开 foot 时自动 attach 或创建 tmux main session，而不是进入空 shell。

## 问题陈述

当前快捷键只执行默认 terminalCommand，启动一个普通 foot shell；用户希望这个高频入口直接恢复一个持久 tmux 工作区。

## 验收标准

- [ ] SUPER+SHIFT+Enter 生成的 Hyprland keybind 使用 foot 执行 tmux new-session -A -s main。
- [ ] 如果 main session 已存在，快捷键恢复该 tmux session；如果不存在，则创建它。
- [ ] 不改变全局 TERMINAL、foot 默认配置或其他 terminal 用途。
- [ ] 任务文档记录 scope、验证和交付结果。

## 假设 / 约束 / 风险

- **假设**: 桌面环境使用 modules/desktop/hyprland.nix 生成该快捷键。
- **假设**: foot 和 tmux 已由现有 Nix 模块安装。
- **假设**: 固定 tmux session 名为用户确认的 main。
- **约束**: 只做最小行为变更，不重构 terminal 模块。
- **约束**: 不影响 $terminal、$taskManager 或其它 app launcher 对默认 terminal 的使用。
- **风险**: Hyprland exec 行的参数解析若不匹配 foot -e 语义，可能导致 tmux 未启动。
- **风险**: 若 tmux 不在会话 PATH 中，快捷键会打开后立即退出。

## 要点

- Non-goals: 不改变 tmux 配置、不新增 terminal abstraction、不把所有 foot 启动都改为 tmux。
- Recommended path: 在 Hyprland 模块中为该 hotkey 定义专用 tmuxTerminalCommand。

## 范围

- modules/desktop/hyprland.nix 中 SUPER+SHIFT+Return keybind。
- .legion task 文档与后续验证/汇报记录。

## 设计索引 (Design Index)

> **Design Source of Truth**: Design-lite: low-risk single-module shortcut change; no standalone RFC required.

**摘要**:
- 新增一个专用于快捷键的 terminal command，组合现有 terminalCommand 与 tmux create-or-attach 命令。
- 保留通用 terminal 变量不变，避免把其它工具启动入口也改成 tmux。
- 验证以静态检查生成表达式和命令可用性为主。

## 阶段概览

1. **Contract** - 落盘稳定任务契约
2. **Implementation** - 更新 Hyprland terminal hotkey
3. **Verification** - 验证配置变更与命令形态
4. **Closure** - 生成 walkthrough 并写回 wiki

---

*创建于: 2026-05-15 | 最后更新: 2026-05-15*
