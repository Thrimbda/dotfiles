# Axiom Caelestia 锁屏 DPMS 行为修复

## 目标

让 Axiom 的 Caelestia 锁屏在成功加锁后 60 秒可靠关闭显示器，并由物理键盘按键或鼠标移动可靠唤醒显示器而不解除锁定。

## 问题陈述

PR #194 已使 shell QML、Config 插件和运行时闭包对齐。随后现场确认 Quickshell 0.3 的 `WlSessionLock.locked` 在加锁时不发 notify；改为 `secureChanged` 后，手动锁屏 65 秒已使两块显示器进入 `dpmsStatus: false` 且锁仍有效。

同一现场验证发现 QML 的零超时 wake `IdleMonitor` 没有恢复 DPMS。Axiom 当前 `misc:key_press_enables_dpms` 和 `misc:mouse_move_enables_dpms` 均为 `false`，所以 physical input 没有 compositor-native wake path。

## 验收标准

- [x] `IdleMonitors` 从 `WlSessionLock.secureChanged` 而非缺失的 lock-acquisition notify arm timer，且只在 compositor 确认所有锁屏 surface 后创建一次计时器。
- [x] Axiom 的 `misc.key_press_enables_dpms` 和 `misc.mouse_move_enables_dpms` 均设为 `true`，由 Hyprland 的键盘按键或鼠标移动恢复 DPMS，且不解除锁定。
- [x] 解锁仍使用原生 `lockedChanged` 清理 timer-owned DPMS 状态；输入唤醒不会在同一 lock epoch 重启 60 秒计时器。
- [x] 配置属性、插件闭包和 Axiom 的 `lockDpmsTimeout = 60` 继续保持已验证状态。
- [x] 定向构建、补丁/源级断言和部署后现场 smoke 均证明 60 秒 DPMS off、锁屏输入 wake、解锁恢复。
- [x] 不改变 900/1800 秒策略、其他主机默认行为、Hypridle 所有权或 suspend/hibernate 语义。

## 假设 / 约束 / 风险

- **假设**: Axiom 使用的 Quickshell 0.3 保持当前 `WlSessionLock` notify 语义。
- **约束**: 继续由 Caelestia 管理锁屏、DPMS 和 session runner，不加入外部 idle owner 或 wrapper。
- **约束**: 只触及 `IdleMonitors.qml` shell patch、Axiom 的 Hyprland host policy、相应静态测试和任务证据；已合并的 Config 插件闭包修复不回退。
- **约束**: 用户明确接受 Axiom 所有 DPMS-off 场景均由物理键盘/鼠标唤醒；其它主机不改变。
- **风险**: `secureChanged` 与 unlock 的异步顺序必须仅 arm 成功锁，不得让 unlock event 重启 timer。
- **风险**: 部署和 lock-screen smoke 会短暂中断会话，需要保留手动解锁且不自动解锁。

## 范围

- `modules/desktop/caelestia-lock-dpms-shell.patch` 中的 `IdleMonitors.qml`。
- `hosts/axiom/default.nix` 中的 Hyprland `misc` host policy。
- `modules/desktop/tests/caelestia-lock-dpms-patch-test.js` 及现有 Nix patch test。
- Axiom 现场验证与 `.legion/tasks/axiom-lock-dpms-plugin-fix/` 设计、验证和交付证据。

## 非范围

- 修改 Quickshell 自身、Caelestia Config 插件 schema、Nix plugin closure replacement 或其它主机设置。
- 改变 idle timeout、引入 Hypridle、swayidle、脚本轮询，或改变其它主机的 DPMS wake 行为。

## 设计索引

> **Design Source of Truth**: `docs/rfc.md`

**摘要**:
- `IdleMonitors` 订阅 `WlSessionLock.secureChanged`，只在 `secure` 为真时 arm timer，绕过 Quickshell 0.3 缺失的 locked acquisition notify。
- Axiom Hyprland `misc` policy 负责物理输入 DPMS wake；原生 `lockedChanged` 只处理 unlock cleanup。

## 阶段概览

1. **设计修订** - 记录 QML wake failure 并审查 Axiom native DPMS wake policy。
2. **实现** - 保留 secure-gated arm timer，启用 Axiom native DPMS wake。
3. **验证与交付** - 构建、部署、锁屏现场 smoke、审查、walkthrough 和 wiki 写回。

---

*创建于: 2026-08-21 | 最后更新: 2026-08-22*
