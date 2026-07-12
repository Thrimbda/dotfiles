# Dotfiles Caelestia-only Bluetooth Control

## 目标

在整个 dotfiles 中移除 Caelestia 以外的可见蓝牙控制面；所有蓝牙主机仅保留 BlueZ/CLI 与 headless 配对 agent，只有启用 Caelestia 的主机提供图形蓝牙控制。

## 问题陈述

当前共享蓝牙 profile 同时启用 Blueman、Rofi Bluetooth 与 Caelestia。Blueman XDG autostart 绕过了无效的 systemd user unit mask，其 PowerManager/KillSwitch 会在 MediaTek 控制器慢初始化时制造并持久化 rfkill soft block；Caelestia 无法从 off-blocked 恢复，且设备列表让匿名 BLE MAC 排在真实名称前。

## 验收标准

- [ ] 所有蓝牙主机不再暴露 Blueman tray、Blueman Manager 或 Rofi Bluetooth 图形入口
- [ ] 仅启用 Caelestia 的主机提供图形蓝牙开关、扫描、配对和连接控制
- [ ] 保留不可见的 Blueman AuthAgent 或等效窄后端以支持 PIN/passkey 配对，且不得加载电源、rfkill、菜单或托盘控制插件
- [ ] 开机和恢复后 Bluetooth 不处于 soft-blocked，Caelestia 可完成关闭再开启
- [ ] Caelestia 设备列表优先显示有真实名称、已配对或已连接设备，匿名 BLE MAC 不占据主列表
- [ ] 共享配置在所有声明 bluetooth profile 的主机上可求值，并通过相关构建、静态检查与运行时 smoke 验证

## 假设 / 约束 / 风险

- **假设**: BlueZ 和 bluetoothctl 作为底层服务与诊断工具继续保留
- **假设**: 未启用 Caelestia 的主机可以没有图形蓝牙控制面
- **假设**: Blueman AuthAgent 可以与其 UI、电源和 rfkill 插件解耦运行
- **约束**: 不得以 root 运行 Caelestia 或授予宽泛系统能力
- **约束**: 不得通过全局关闭所有 radio 的 systemd-rfkill 恢复来掩盖问题
- **约束**: 不得为匿名 BLE 广播猜测或伪造产品名
- **约束**: 不得保留第二套可见蓝牙控制面
- **风险**: Blueman 插件裁剪错误可能破坏 PIN/passkey 配对
- **风险**: Caelestia 上游 QML 补丁可能随 flake 更新发生漂移
- **风险**: 共享 profile 改动可能影响未启用 Caelestia 的其他主机
- **风险**: MediaTek 控制器慢初始化要求启动和恢复策略保持确定性

## 要点

- **唯一控制面**: 所有主机移除 Blueman 与 Rofi Bluetooth 的可见入口；只有启用 Caelestia 的主机拥有图形蓝牙控制。
- **窄配对后端**: 保留无菜单、无托盘、无电源或 rfkill 权限面的 headless AuthAgent，避免 PIN/passkey 配对能力回退。
- **状态收敛**: 删除主动进入 rfkill blocked 状态的恢复逻辑，不以全局 radio 策略掩盖单一蓝牙问题。
- **名称体验**: Caelestia 优先显示已连接、已配对和提供真实名称的设备；匿名广播不得挤占主列表。

## 非目标

- 不删除 BlueZ、`bluetoothctl` 或底层诊断能力。
- 不为未启用 Caelestia 的主机提供替代图形蓝牙管理器。
- 不根据 MAC、OUI 或厂商私有广播猜测匿名设备的产品名。
- 不扩大 Caelestia、Quickshell 或配对 agent 的系统权限。

## 范围

- `modules/profiles/hardware/bluetooth.nix`
- `modules/desktop/apps/rofi.nix`
- `modules/desktop/caelestia.nix`
- 必要的共享/主机条件化配置
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/`

## 设计索引 (Design Index)

> **Design Source of Truth**: [docs/rfc.md](docs/rfc.md)

**摘要**:
- 从共享 profile 移除 Blueman system service、XDG UI 暴露和主动 rfkill block 路径
- 仅以受控 headless 方式保留配对 agent，Caelestia 成为唯一图形控制面
- 删除 Rofi Bluetooth launcher，并在 Caelestia 列表中优先真实名称、降级匿名广播
- 用多主机求值、Axiom 构建及部署后状态/配对 smoke 验证行为

## 阶段概览

1. **Design** - 记录现状证据并形成 RFC
2. **Implementation** - 在隔离 worktree 中实现全局控制面精简
3. **Verification** - 验证多主机求值与 Axiom 构建
4. **Delivery** - 完成代码审查与 walkthrough

---

*创建于: 2026-07-11 | 最后更新: 2026-07-11*
