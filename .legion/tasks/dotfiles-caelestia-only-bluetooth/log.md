# Dotfiles Caelestia-only Bluetooth Control - 日志

## 会话进展 (2026-07-11)

### ✅ 已完成

- 确认 rfkill、BlueZ、Quickshell、Caelestia 与 Blueman 的状态交互。
- 确认共享 Blueman XDG autostart 绕过 `blueman-applet.service` mask。
- 确认任务范围为所有启用 bluetooth profile 的主机。
- 创建基于 `origin/master` 的隔离 worktree 与 PR 分支。

### 🟡 进行中

- 编写唯一控制面、headless AuthAgent、名称策略与迁移验证 RFC。

### ⚠️ 阻塞/待定

- 无。

---

## 关键文件

- `modules/profiles/hardware/bluetooth.nix` - 共享 BlueZ、Blueman 与恢复策略。
- `modules/desktop/apps/rofi.nix` - Rofi Bluetooth 可见入口。
- `modules/desktop/caelestia.nix` - Caelestia 包装、运行环境与潜在上游补丁入口。

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 所有主机移除 Caelestia 以外的可见蓝牙控制面 | 避免多个状态语义不同的控制面竞争 | 仅修复 Axiom | 2026-07-11 |
| 保留 headless AuthAgent | Quickshell 当前不提供 BlueZ passkey agent | 完全删除 Blueman 并接受配对回退 | 2026-07-11 |
| 未启用 Caelestia 的主机不提供替代 GUI | 用户明确选择全局精简 | 按桌面类型保留 Blueman/Rofi | 2026-07-11 |

---

## 快速交接

**下次继续从这里开始：**

1. 在 worktree 中完成 `docs/rfc.md`。
2. 运行 `review-rfc`，通过后才进入实现。

**注意事项：**

- Base: `origin/master` at `d49234ed`.
- Branch: `legion/dotfiles-caelestia-only-bluetooth-control`.
- Worktree: `.worktrees/dotfiles-caelestia-only-bluetooth/`.
- subagent 不直接改写 `.legion` 三文件。

---

*最后更新: 2026-07-11 by OpenCode*
