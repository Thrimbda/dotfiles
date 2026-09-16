# 远程桌面 WireGuard 网络

## 目标与边界

Charles 通过 Ant 中转访问 Axiom Sunshine 和 Charlie Apple 屏幕共享。桌面数据通过 WireGuard 加密数据报传输，取消 FRP 对这些流量的可靠流封装。四台机器后台自动启动；默认路由、DNS、其他应用的 Clash 策略保持原状。

| 主机 | 隧道地址 | 用途 |
| --- | --- | --- |
| Ant | 10.77.0.1 | UDP 51820 中转 |
| Axiom | 10.77.0.2 | Sunshine |
| Charlie | 10.77.0.3 | Apple 屏幕共享 |
| Charles | 10.77.0.4 | Moonlight / 屏幕共享客户端 |

Ant 每个 peer 只允许自身 /32 源地址。转发仅允许 Charles 与两个桌面服务通信及诊断 ICMP，不开放任意跨主机访问。各终端只添加指定 peer 的 /32 路由，不设置默认路由或 DNS；Clash 排除 Ant 公网地址及该专用内网段。Ant 和两台服务端的 SSH 通道独立保留。

密钥为每台机器独立生成，以现有机器 SSH identity 加密到各自 `hosts/<host>/secrets/desktop-wireguard.age`。明文仅在权限受限的运行目录使用，Nix store 与仓库只保存密文及公钥。Linux 用 systemd，macOS 用系统 LaunchDaemon；终端每 25 秒保活，维持 NAT 映射。

## 迁移与回滚

先部署独立 WireGuard 服务，保留既有桌面 FRP。检查握手、路由、服务访问控制和两个应用的真实会话；再停用桌面 FRP。Mac `charlie-screen` 更新到 Charlie 的私有地址；Moonlight 更新 Axiom 地址并保留原配对身份。

回滚时恢复桌面 FRP 作业与原客户端入口，再停止 WireGuard 作业。不得切换未包含有效桌面配置的 Axiom 整机 generation。独立服务产物使用 GC roots 保留，后续由相同 Nix 声明接管。

## 验收

需验证普通及高性能 Mac 共享、Moonlight 实际画面、隧道重启恢复、Clash 重载后路由、拒绝非桌面转发。整机重启、FileVault 首次解锁与长期弱网性能分别记录，不能用服务 active 或 TCP 握手代替实际桌面验收。

WireGuard 不重传丢失的音视频数据包，但 Wi-Fi 重试、应用编码依赖与客户端排队仍可能产生延迟；本迁移不保证消除弱网卡顿。

## 当前部署与验证（2026-09-16）

- 四台 WireGuard 均已部署并完成握手。Moonlight 添加 `10.77.0.2` 后沿用 Axiom 原配对身份，实际画面正常，UDP socket 源地址为 `10.77.0.4`，Ant 转发计数持续增长。
- Axiom 的 `frpc-sunshine.service` 已停止并屏蔽。AutoSSH、管理 FRP 和 SSH 保持 active。Axiom WireGuard 服务重启后，私有 Sunshine 接口恢复响应。
- Charlie `10.77.0.3:5900` 返回 Apple RFB banner；普通及高性能会话仍等待 macOS 登录认证，尚不能宣称通过。Mac 桌面 FRP 和 Ant `frps-sunshine` 继续保留，验收后再移除。
- Charlie LaunchDaemon 收到 SIGTERM 后自动从 runs=1 变为 runs=2，并重新握手。Charles 配置相同的 KeepAlive，但本机重启测试因 Touch ID 等待而取消，未执行；现有服务继续运行。
- Ant 转发拒绝 Charles 到 Axiom/Charlie 的 TCP 22；桌面 TCP 端口可达。尚未用实际高性能共享流验证 UDP 5900–5902。
- 整机重启、FileVault 解锁前可用性、长期弱网延迟未验收。启动项已配置，不应把服务重启等同于整机启动验收。

### Clash 与客户端入口

Charles 和 Charlie 的以下两个文件均仅追加 `tun.route-exclude-address` 中的 `106.15.156.143/32` 和 `10.77.0.0/24`，原有条目保留：

- `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/profiles/Merge.yaml`：持久合并配置。
- 同目录 `clash-verge.yaml`：当前生效配置，通过本机控制 socket 重载。

各原文件备份为同目录 `.pre-wireguard` 后缀文件，权限 0600。重载后 Ant 公网地址经物理网卡，专网地址经 WireGuard utun；Axiom 的专网回复经 `wgdesk`，其他 Clash 策略未改。

`charlie-screen` 新产物为 `/nix/store/q0w9xdjxf1iwb4s6ymg2n4m7hwdlx96k-charlie-screen`，已加入 Charles 的用户 Nix profile，同时更新原有 `~/.local/bin/charlie-screen` 符号链接。后续完整 Darwin 激活同样会安装该入口；用户 profile 的临时覆盖可在确认系统入口更新后移除。

### 独立服务部署

此次只部署原生服务产物，没有替换系统 generation 或整个 systemd 目录：

| 主机 | 固定产物 |
| --- | --- |
| Ant | `/nix/store/9dbx3237f304a2ljl8hmbyfj2nw0mnz4-unit-wg-quick-wgdesk.service` |
| Axiom | `/nix/store/iak4ivip2gq1i2xgw6nazvg1mvkb9kz7-unit-wg-quick-wgdesk.service` |
| Charles | `/nix/store/7jd6k37mydkx43lzzhfwfxhpldqr6w2m-org.nixos.desktop-wireguard.plist` |
| Charlie | `/nix/store/3jc12d38jqv8rvpaq837xcrsd9hb3acp-org.nixos.desktop-wireguard.plist` |

每台使用 `/nix/var/nix/gcroots/desktop-wireguard` 保留相应产物。Linux 的 `/etc/systemd/system.control/wg-quick-wgdesk.service` 指向原生 unit；`multi-user.target.d/desktop-wireguard.conf` 添加 Wants。Mac 安装 `/Library/LaunchDaemons/org.nixos.desktop-wireguard.plist`，配置 RunAtLoad 和 KeepAlive，日志在 `/var/log/desktop-wireguard.log`。

之后完整 Nix 激活前，应先合入并保留有效的 Sunshine/Caelestia 启动修复，再清理已被声明式配置接管的临时 unit 覆盖；不能直接用未包含这些修复的 master 整机切换 Axiom。

### 回滚入口

恢复 Axiom 桌面 FRP 时，先将 `/var/lib/desktop-wireguard/rollback/frpc-sunshine.service` 还原到 `/etc/systemd/system.control/`，执行 daemon-reload 并启动该服务，再将 Moonlight 地址改回原 Ant 入口。Ant 桌面 FRP 和原云防火墙规则尚保留。Mac 原 FRP 入口仍可通过 `vnc://127.0.0.1:15900` 使用。

停止 WireGuard 时，Linux 停止 `wg-quick-wgdesk` 并移除本次专用启动覆盖；Mac 对上述专用 plist 执行 launchctl bootout。仅处理此次 WireGuard 作业，保留管理通道。私钥不得使用 `wg showconf` 或 `wg show all dump` 输出。
