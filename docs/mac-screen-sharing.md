# Charles 连接 Charlie：Apple 屏幕共享

Charles 通过 Ant 中转的 WireGuard 访问 Charlie 的 Apple 屏幕共享。旧的 FRP
STCP 通道（`127.0.0.1:15900`，QUIC/UDP 7001）已在 commit `882ba252` 随桌面
中转整体迁移到 WireGuard 时退役，本文描述当前路径。

## 使用

```sh
charlie-screen          # 自动选择链路并打开屏幕共享
charlie-screen --check  # 只打印会使用的地址，不打开窗口
```

`charlie-screen` 的选择顺序：

1. 本机有 `192.168.10.0/24` 地址时，探测 Charlie 的 LAN 地址
   `192.168.10.4:5900`；拿到 `RFB ` banner 就使用它。在家时这是直连，
   不经过 Ant。
2. 否则检查本机是否有 `10.77.0.4` 的 WireGuard 接口，再探测
   `10.77.0.3:5900`。
3. 两条都不通时以非零状态退出，并分别打印 LAN / WG 的失败原因，提示检查
   `/var/log/desktop-wireguard.log`、
   `launchctl print system/org.nixos.desktop-wireguard` 和 Charlie 的共享设置。

也可以在屏幕共享 App 中直接连接 `vnc://10.77.0.3`。不要用主机名
`charlie`：它会被 Clash 的 fake-ip 解析成 `198.18.x.x`，TCP 能建立但拿不到
RFB banner。

连接路径：

```text
Charles charlie-screen
  → 10.77.0.3:5900（WireGuard，Charles 10.77.0.4）
  → Ant 10.77.0.1:51820 中转
  → Charlie 10.77.0.3:5900
```

在家且与 Charlie 同网时，`charlie-screen` 会改走
`192.168.10.4:5900`，不经过 Ant。Apple 高性能模式还需要 UDP 5900–5902；
Ant 的 WireGuard 转发规则已允许两台 Mac 之间的这些端口。

## 前提与配置

- Charlie：系统设置 → 通用 → 共享 → 屏幕共享开启，访问名单只包含 `c1`。
  对应声明在 `hosts/charlie/modules/screen-sharing.nix`。
- Charles：`hosts/charles/modules/screen-sharing.nix` 生成 `charlie-screen`
  并加入 `environment.systemPackages`；`config/wireguard/darwin.nix` 生成
  LaunchDaemon `org.nixos.desktop-wireguard`。
- WireGuard 拓扑、Ant 端口限制和 Clash 排除项见
  [desktop-wireguard.md](desktop-wireguard.md)。Charles 和 Charlie 的 Clash
  Verge `Merge.yaml` 必须把 `10.77.0.0/24` 与 `106.15.156.143/32` 排除出
  TUN，否则屏幕共享流量会被 Clash 劫持。
- macOS LaunchDaemon 使用
  `/bin/sh -c "/bin/wait4path <start> && exec <start>"` 等待 Nix store
  挂载后再启动；直接 exec store 脚本会在开机早期失败（`EX_CONFIG`，exit
  78）。冷启动前需要先解锁 FileVault。

## 分辨率

Charlie 保留用户选择的显示模式。2026-09-16 复核为 HiDPI：界面尺寸
2560×1440、渲染尺寸 5120×2880、60 Hz。不要通过登录任务修改实体显示器模式；
当前普通屏幕共享不支持独立于实体显示器的远程分辨率限制。

## 检查与故障排查

```sh
# Charles
charlie-screen --check
launchctl print system/org.nixos.desktop-wireguard | grep -E 'state|runs|pid'
ifconfig utun11 | grep 'inet 10.77.0.4'
tail -n 20 /var/log/desktop-wireguard.log

# Charlie（经 SSH）
ssh charlie 'nc -G 3 -z 127.0.0.1 5900'
```

- `--check` 输出 `10.77.0.3` 但连接失败：检查 Ant 上的 peer 握手和 Charlie
  的共享服务，不要先怀疑 Clash。
- `--check` 报 `WireGuard interface (10.77.0.4) is down`：LaunchDaemon 没有
  起来，先看 `/var/log/desktop-wireguard.log` 和 plist。
- `--check` 在本机于 `192.168.10.0/24` 时没有选 LAN：确认 Charlie 的 LAN 地址
  仍是 `192.168.10.4`，以及 Charlie 的 5900 在监听。
- 想按名字连接时不要用 `charlie`（Clash fake-ip），用 `10.77.0.3` 或
  `charlie-screen`。

## 历史

- 2026-09-14：用 Apple 屏幕共享替换 RustDesk，经 Ant FRP STCP
  （`127.0.0.1:15900`）。
- 2026-09-16：FRP 屏幕共享通道改用 QUIC/UDP 7001。
- 2026-09-16（commit `882ba252`）：桌面中转整体迁移到 WireGuard，FRP STCP
  入口退役，屏幕共享改为 `10.77.0.3`。
- 2026-10-19：修复 WireGuard LaunchDaemon 在开机时抢跑 Nix store 的竞态；
  `charlie-screen` 增加 LAN 优先、RFB banner 校验和 `--check`。
