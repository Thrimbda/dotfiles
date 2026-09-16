# 远程桌面 WireGuard 网络

Charles 通过 Ant 中转访问 Axiom Sunshine 和 Charlie Apple 屏幕共享。桌面流量通过 WireGuard 加密数据报传输；Linux 使用 systemd，macOS 使用系统 LaunchDaemon，均自动启动，无需手动打开 VPN 应用。AutoSSH 和用于管理及应用入口的 FRP 保留。

| 主机 | 隧道地址 | 用途 |
| --- | --- | --- |
| Ant | 10.77.0.1 | UDP 51820 中转 |
| Axiom | 10.77.0.2 | Sunshine |
| Charlie | 10.77.0.3 | Apple 屏幕共享 |
| Charles | 10.77.0.4 | Moonlight / 屏幕共享客户端 |

## 路由与访问范围

各终端仅添加所需的 /32 路由，不修改默认路由或 DNS。Ant 为每个 peer 限定自身源地址，只转发以下通信及诊断 ICMP：

- Charles → Axiom：TCP 47984、47989、48010，UDP 47998–48000。
- Charles → Charlie：TCP 5900；两台 Mac 之间双向 UDP 5900–5902，供高性能屏幕共享使用。
- 已建立连接的回复；其他跨主机流量拒绝。

Charles 和 Charlie 的 Clash Verge 持久配置 `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/profiles/Merge.yaml` 在 `tun.route-exclude-address` 中排除 `106.15.156.143/32` 和 `10.77.0.0/24`。生效配置已重载；原文件的同目录 `.pre-wireguard` 备份权限为 0600。Axiom 保留 Ant 公网直连规则，专网回复使用主路由表的 WireGuard 路由。

Ant 公网桌面入口只有 UDP 51820。旧桌面 FRPS 7001、Sunshine FRPC、Mac FRPC/STCP visitor 均从运行配置移除；管理 FRPS 7000 与反向 SSH 不受影响。

## 客户端与密钥

Moonlight 使用 Axiom `10.77.0.2`，沿用原配对身份。`charlie-screen` 打开 `vnc://10.77.0.3`；也可以在“屏幕共享”应用中保存该地址并选择普通或高性能模式。

每台机器使用独立 WireGuard 密钥，私钥以机器 SSH identity 加密保存于 `hosts/<host>/secrets/desktop-wireguard.age`。明文只进入权限受限的运行目录，Nix store 和 Git 仅保存密文及公钥。端点每 25 秒保活。

Linux 服务名为 `wg-quick-wgdesk.service`，运行目录 `/run/desktop-wireguard`；Mac 服务名为 `org.nixos.desktop-wireguard`，运行目录 `/var/run/desktop-wireguard`，日志 `/var/log/desktop-wireguard.log`。

## 系统激活

在 Axiom 构建 Linux system closure，复制到 Ant 后执行原生 switch；Ant 不进行构建。两台 Mac 使用各自 Darwin system closure 激活。不得通过复制或手改 `/etc/systemd/system` 整个目录拼接系统 generation。

完整配置包含 Sunshine 的 NVENC/headless 输出、Caelestia 对虚拟显示器的 DPMS 处理，以及 PR #238 的显卡选择和每会话启动 hooks。Axiom 不再导入已退役的 RustDesk 服务模块。

首次完整 switch 时，清理此前仅用于分阶段部署的 WireGuard unit 覆盖、启动 target drop-in、Sunshine 参数覆盖和手动 Home Manager 文件链接，由原生系统配置接管。其他任务的覆盖保持原状。旧 system generation 和本次专用备份用于回滚。

## 验收与限制

2026-09-16 用户确认 Moonlight 和 Mac 屏幕共享已全部验收，包括此前待验证的普通/高性能模式。本次据此撤掉桌面 FRP 并进行完整系统 switch。

此前已直接验证四个 peer 握手、Sunshine serverinfo、Apple RFB banner、Moonlight 实际画面及私有源地址、Ant UDP 转发计数、Clash 重载后的路由，以及拒绝通过专网访问两台服务端的 SSH。Axiom 服务重启恢复、Charlie LaunchDaemon 被终止后自动重启并重新握手均通过。

用户体验验收与本次系统切换检查分别记录：switch 后复核当前 system profile、服务状态、握手、路由和桌面接口，不能把 switch 等同于又完成一次整机重启。Mac FileVault 冷启动前仍需先解锁系统盘。

WireGuard 不重传丢失的数据报，但 Wi-Fi 重试、编码依赖及客户端排队仍可造成延迟；该方案不保证消除所有弱网卡顿。

## 故障排查与回滚

先检查 WireGuard 服务、握手、Ant 物理网络路由和上述桌面端口；避免用 `wg showconf` 或 `wg show all dump` 输出私钥。普通 `wg show` 会隐藏私钥。

系统切换异常时使用保留的原生 system generation 回滚。若要恢复旧桌面 FRP，必须同时恢复对应服务和 Ant 云防火墙规则，并把客户端改回旧地址；仅恢复客户端地址不会重新建立已移除的中转。
