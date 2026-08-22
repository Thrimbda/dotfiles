# Axiom Caelestia DPMS 插件修复 - 日志

## 会话进展 (2026-08-21)

### ✅ 已完成

- 从现场 QML、配置、derivation 和闭包证据确认 shell/plugin 补丁错配根因。
- 完成 split-patch 和精确 plugin 依赖替换的 RFC 审查。
- 拆分 C++ Config 与 QML 补丁，并将 shell buildInputs 与 passthru.plugin 指向打补丁插件。

(暂无)
### 🟡 进行中

- 初始化任务日志。
- 实现 Config plugin 与 shell 运行时闭包对齐。
- 验证构建闭包、插件 qmltypes 和运行时路径。
### ⚠️ 阻塞/待定

(暂无)

(暂无)
(暂无)
---

## 关键文件

- **`modules/desktop/caelestia.nix`** [completed]
  - 作用: 将 Caelestia shell 与 Config plugin 的补丁和依赖闭包显式对齐。
  - 备注: 以 store path 精确替换唯一旧 plugin 输入。
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| (暂无) | - | - | - |
---

## 快速交接

**下次继续从这里开始：**

1. (none)

**注意事项：**

(暂无)

(暂无)
---

*最后更新: 2026-08-21 16:06 by Legion CLI*

## 会话进展 (2026-08-22)

### ✅ 已完成

- 现场确认 Config plugin closure 已正确加载、`lockDpmsTimeout = 60` 生效。
- 发现并修复 Quickshell 0.3 在 lock acquisition 不发 `lockedChanged` 的问题：timer 改由 `secureChanged` arm。
- 为 Axiom 启用 Hyprland 原生键盘按键和鼠标移动 DPMS wake。
- 完成 65 秒关屏、locked pointer wake、同 epoch 65 秒 no-rearm、timer-owned DPMS unlock cleanup 的受控 runtime 验证。
- 临时关闭的 Howdy/指纹认证已恢复为 `true`，最终源码不含认证设置变更。

### 🟡 进行中

- 完成 PR、merge、worktree cleanup 和主工作区刷新。

### 关键决策

| 决策 | 原因 | 日期 |
|------|------|------|
| 在 `secureChanged` 时 arm lock DPMS | `lockedChanged` 仅可靠覆盖 unlock，不能表示 compositor 已确认锁屏。 | 2026-08-22 |
| 使用 Axiom Hyprland 原生 DPMS wake | lock-scoped QML wake monitor 未可靠接收 physical input resume；compositor 可在锁输入前恢复显示器。 | 2026-08-22 |
