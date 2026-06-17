# Axiom Default Modularization RFC

## 背景
Axiom host 已经稳定运行，但 `hosts/axiom/default.nix` 同时承担主机事实、服务定义、健康检查脚本、Cloudflared/Gatus/Opencode glue、reverse SSH、桌面 runtime migration 和硬件 workaround。当前结构让端口、用户、路径、hostname、timer 和 restart policy 分散在多个位置。

## 决策
采用“小模块 + host facts”路线：Axiom host 只声明主机事实和模块启用，重复的 service mechanics 下沉到 `modules/services/*`。不为没有当前消费者的旧字段保留兼容别名。

## 选项
- **选项 A: 只清理 host 内重复项**。改动小，但 healthcheck/autossh/opencode 仍然继续堆在 host 文件里，无法解决核心耦合。
- **选项 B: 抽出 focused modules**。新增少量服务模块和 helper，把高重复 mechanics 下沉，Axiom host 只保留事实。改动适中，最符合目标。
- **选项 C: 重写整个 desktop/service profile**。理论上最干净，但会把 Hyprland/Caelestia/monitor/keybind 等非本任务问题一起拉进来，风险和范围过大。

选择 B。

## 模块边界
- `modules/services/reverse-ssh.nix`: 管 reverse autossh tunnel 的 systemd service、known host、package/path、restart policy。Axiom 传 remote host/key/ports/user 即可。
- `modules/services/opencode-server.nix`: 管 local opencode server service，以及可选 public hostname、Gatus endpoint、Cloudflared ingress 数据输出。
- `modules/services/healthchecks.nix` 或局部 helper: 管 systemd timer/service + failure counter + threshold + restart target 的重复骨架。具体 check command 仍由调用方传入。
- `modules/services/calibre.nix`: 清掉硬编码 `c1`，改用当前 user facts。
- `hosts/axiom/default.nix`: 保留显示器、音频硬件事实、Cloudflared tunnel id/secret、Axiom-specific healthcheck command、ToDesk、virt、firewall 的最小必要部分。

## 删除策略
直接删除以下类型配置，不加兼容层：
- 已由 workstation/profile/module 默认提供的重复启用项。
- Caelestia 不消费的 wallpaper `mode`。
- Axiom 当前 cloudflared `http2` 不需要且无本地消费者的 QUIC/ephemeral firewall 开口。
- 未用 let binding 和明显重复字面量。

## 保留策略
- 保留 Caelestia `general.idle` persisted-config migration，因为已有 mutable `shell.json` 会绕过新 seed settings。
- 保留 Hyprland 0.53.x `cm_enabled = false` workaround。
- 保留 reverse SSH endpoint key healthcheck 语义，包括失败计数和阈值后 restart。

## 验证
- `nix eval` 检查 Axiom 的关键 facts：opencode service command、cloudflared ingress、gatus endpoints、reverse SSH service、healthcheck timers、firewall ports。
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 必须成功。

## 回滚
这是纯 Nix 配置重构。若 build 或 facts 检查失败，回滚本分支改动即可。若部署后某个 service 行为异常，可先回滚对应模块调用到原 host-inline 写法，但不要保留并行双实现。
