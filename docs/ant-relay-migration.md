# Acorn → Ant 中转迁移

截至 2026-09-16（Asia/Shanghai），在线机器的反向 SSH、主 FRP、Sunshine FRP 和网页中转均已转向 Ant。Ant、Acorn 已部署原生 NixOS 配置。Sunshine 的无头显卡选择已修正，Moonlight 经 Ant 实际显示 3840×2160、约 60 FPS 的 HEVC 桌面画面，远程键盘输入通过验证。

## 入口与验证

| 用途 | 入口 | 本次结果 |
| --- | --- | --- |
| Ant 管理 | `ssh ant` → `106.15.156.143:22` | 已验证身份与 sudo |
| Charlie SSH | `ssh charlie-tunnel` → Ant 回环 2222 → Charlie 22 | 登录返回 `charlie` |
| Axiom AutoSSH | `ssh axiom-tunnel` → Ant 回环 2223 → Axiom 22 | 登录返回 `axiom` |
| Axiom FRP SSH | Ant TCP 2225 → Axiom 22 | 独立完成 SSH 主机密钥校验与登录 |
| Charlie 屏幕共享 | Charles `127.0.0.1:15900` → Ant QUIC 7001 → Charlie 5900 | RFB 握手正常；保留 #234、#236 的 QUIC 与实体显示器设置 |
| Axiom Sunshine | Ant QUIC 7001 → Sunshine 控制与媒体端口 | 六个代理在线；3840×2160 HEVC 约 60 FPS；远程键盘可打开终端 |
| Axiom 网页 | 原 `.0xc1.wang` 域名 → Ant HTTPS → FRP → Axiom gateway | 三个 gateway 经 Ant 的 `/healthz` 均返回 204 |
| Acorn 常驻应用 | `ssh azar`、原应用域名 | nginx、auth-mini、constxd、vaultwarden 均 active |

`ssh charlie` 保留认证后的局域网优先探测，失败后经 Ant。Charlie 专用隧道账户仅允许回环 2222 的远程转发，不允许 shell 或任意本地转发。Ant 不公开 VNC 5900。

## 已部署配置

### Ant

原生 NixOS 版本：

`/nix/store/kwi1wx30l1s6vx7i82bwq92q248byrmk-nixos-system-ant-efi-qcow2-26.05.7813.0dd31db7e6db`

在 Axiom 构建，经 SSH 复制到 Ant。先 `dry-activate` 检查，再用带自动回退定时器的 `test` 激活；SSH、FRPS、nginx、认证 gateway 和 systemd 消息总线通过检查后，设置 system profile 与启动项，取消回退定时器。RustDesk 已从原生配置中移除，临时 mask 已移入备份。

| 协议 | 端口 | 用途 |
| --- | --- | --- |
| TCP | 22、443 | SSH 与 HTTPS 中转 |
| TCP | 7000 | Axiom 主 FRP |
| TCP/UDP | 7001 | Sunshine 和 Mac STCP 的 QUIC 中转 |
| TCP | 2225 | Axiom FRP SSH |
| TCP | 47984、47989、48010 | Sunshine 控制 |
| UDP | 47998–48000 | Sunshine 媒体 |

`frps-acorn.0xc1.wang`、`status-axiom.0xc1.wang`、`opencode-axiom.0xc1.wang`、`pi-axiom.0xc1.wang` 的 DNS 指向 Ant，原有 TTL 和代理设置保留。认证 issuer `auth.0xc1.wang` 留在 Acorn。RustDesk 的误迁移已撤回：服务停用、Ant 对应云防火墙规则删除，旧 DNS 恢复原值，数据没有删除。

### Acorn

原生 NixOS 版本：

`/nix/store/hgfsqg6myziprafjfnhiya19fmmz4jqz-nixos-system-acorn-26.05.7813.0dd31db7e6db`

构建在 Axiom 完成。Acorn 的 FRP、RustDesk、Charlie 隧道账户及迁出网页的 vhost/证书续期任务已从配置移除，保留常驻应用。流量采样只统计 Acorn 的 nginx 和 SSH，保留历史 JSON 结构。

第一次原生 `test` 因旧 `rustdesk.target` mask 的残留启动请求返回状态 4；常驻应用和管理通道当时均正常。清理本任务的七项覆盖后，第二次原生 `test` 返回 0，failed units 为零。`/etc/systemd/system` 已恢复标准的 `/etc/static/systemd/system` 链接。system profile、当前系统与默认启动项一致。既有 `constxd.service.d` 覆盖保持原样。

Ant 和 Acorn 的临时覆盖备份均位于 `/var/lib/ant-relay-migration/retired-overrides/`，不参与当前服务加载。旧中转端口在 Acorn 没有监听。

### Axiom

继续使用用户恢复的原生系统：

`/nix/store/3zcfq418mqrd1bcsn4kpimca4syqgq47-nixos-system-axiom-26.05.7813.0dd31db7e6db`

该版本的 AutoSSH 已指向 Ant，但两个 FRPC 仍指向 Acorn。此次只将原生 Nix 构建的三个 unit 安装为 `/etc/systemd/system.control/` 中的持久覆盖：

| unit | 产物 |
| --- | --- |
| `frpc.service` | `/nix/store/8zqkh31b6wlm0jsrk4l8mp9jb7acaypl-unit-frpc.service` |
| `frpc-ant-direct-route.service` | `/nix/store/fx9vw84cw4vjvq5nds1chimbbgrpzqz2-unit-frpc-ant-direct-route.service` |
| `frpc-sunshine.service` | `/nix/store/qdb1dw89wqpqqymr44jhwycardsslz3m-unit-frpc-sunshine.service` |

三个产物分别注册在 `/nix/var/nix/gcroots/ant-relay-<unit-name>`。主 FRPC 的启动依赖会拉起 Ant 直连路由；优先级 8501 的规则使 Ant 流量走 main 路由表。切换路由后旧 AutoSSH 连接曾无法转发，已通过新 FRP SSH 入口重启客户端并终止 Ant 上对应旧会话，随后回环 2223 恢复。

Axiom 未再次切换整机 generation，保留恢复后的桌面、Sunshine 和其他服务。后续整机构建应先纳入仍在独立分支中的有效桌面配置，再核对并移除这三个覆盖，避免覆盖继续遮挡新 unit。当前 default branch 不包含完整 Sunshine 桌面部署，不能直接把它视为 Axiom 当前整机的完整来源。

### Charles / Charlie

保留已合并的 #234、#236：两端 FRPC 通过 Ant UDP 7001 使用 QUIC，屏幕共享入口仍是 `127.0.0.1:15900`，不修改实体显示器模式。迁移的 SSH 配置及 Charlie AutoSSH 目标为 Ant。

Charlie FRPC 是以 c1 运行的系统 LaunchDaemon；AutoSSH 和 Charles FRPC 是用户 LaunchAgent，依赖用户登录。对应独立 launchd 产物与 GC roots 的部署记录见 [Mac 屏幕共享](mac-screen-sharing.md)。本次未重启 Mac，也未验证 FileVault 冷启动首次解锁。

## Sunshine 图像修复与验证

实际测试经 Ant 完成 Sunshine serverinfo、Moonlight 应用列表及加密会话协商；Sunshine 日志确认 `CLIENT CONNECTED`。三个 TCP、三个 UDP 代理均在线。

第一轮拉流显示黑屏，日志先出现 Wayland `Frame capture failed`，随后重复 `OpenEncodeSessionEx failed: unsupported device (2)`。重启 Sunshine、新建图形会话、临时选择 NVIDIA EGL 以及软件编码都没有解决采集失败；这些测试覆盖已撤回。

根因是无实体显示器连接时的采集设备选择：当前 Sunshine 2026.516.143833 的 `resolve_render_device()` 在没有检测到带显示器的设备时回退到 `/dev/dri/renderD128`，在 Axiom 上这对应 AMD 核显；Hyprland 则由 RTX 5090 渲染。Wayland 协议记录显示尺寸与格式协商成功，但 compositor 随后拒绝帧复制。设置 `adapter_name=/dev/dri/by-path/pci-0000:01:00.0-render`，使采集缓冲区与桌面使用同一 NVIDIA 设备后，错误消失。[对应版本源码](https://github.com/LizardByte/Sunshine/blob/v2026.516.143833/src/platform/linux/misc.cpp#L1262)

15:02 的 Moonlight 实测显示 3840×2160 HEVC、约 60 FPS 的桌面画面，远程快捷键能打开终端。首次成功会话短时观察的网络丢帧为 0%，网络延迟约 38–77 ms；这不是长期性能保证。持久化修正后重启 Sunshine、重新连接仍有画面；启动阶段可见短时丢帧，未完成长时间性能评估。测试会话已结束。

修正已加入 `hosts/axiom/modules/sunshine-relay.nix`。运行中的独立 Sunshine 部署通过 `/home/c1/.config/systemd/user/sunshine.service.d/50-nvidia-adapter.conf` 持久覆盖 ExecStart，保留当前二进制和完整配置，仅追加该 adapter 参数。之后纳入完整桌面配置部署时，应让原生 Sunshine 配置接管此参数并移除该用户覆盖，避免它固定旧二进制/配置路径。GPU 驱动、物理显示器模式未改动，所有临时编码、EGL、Wayland 与 Hyprland 日志设置已恢复。

14:41 曾发生独立的全机内存耗尽：内核记录 `acceptance-c08f` 进程占用约 43 GiB RSS、约 22 GiB swap，OOM 杀掉桌面会话内的 Quickshell，继而结束整个 Hyprland 会话。该进程随后已退出，内存恢复。新图形会话未重新拉起 `hyprland-session.target`；本次已启动该 target 和 Sunshine。没有重启整机，也未追溯或改动该测试进程所属工作。

音频、长时间流畅度与整机冷启动恢复尚未验收。

## 2026-09-15 故障记录

最初运行时迁移曾验证成功。后续自定义复制系统版本时改变了 systemd 配置目录结构，激活期间重载超时，导致 Axiom 和 Acorn 管理通道异常。该复制方式已弃用。Acorn 通过恢复原生目录结构并重新注册 systemd 消息总线恢复；Axiom 由用户恢复后于 9 月 16 日继续迁移。

故障版本 `/nix/store/vv24h1gdpp32b5yf2n6acj177xhz2xgx-nixos-system-axiom-ant-relay-20260915` 与 `/nix/store/3mjv5a359kka4nr2wj1y185m4z9dyp5j-nixos-system-acorn-ant-relay-20260915` 不应再次激活。备份保留用于追溯。

离线 `hosts/azar` 的 2224 AutoSSH 仅更新源目标，未进行运行验收。它不是 `ssh azar` 连接的 Acorn 主机。

## 配置检查

Ant、Acorn 原生系统和 Axiom 三个 relay unit 构建成功。FRP 渲染测试共 9 项通过（包含 age 集成、错误凭据、权限、转义及符号链接检查），`git diff --check` 通过。最终四台主机的 SSH 身份检查及 Acorn/Ant HTTPS TLS 校验通过。
