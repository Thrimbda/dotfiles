# Axiom：Sunshine / Moonlight 远程桌面

Charles 上打开 `~/Applications/Moonlight.app`，选择 **Axiom → Axiom Desktop**。主机地址是 `8.159.128.125`，已完成配对。默认 1920×1080、60 FPS、20 Mbps、HEVC、硬件解码，启用远程桌面鼠标模式。用 `Ctrl+Alt+Shift+Q` 断开，再点击播放按钮恢复桌面。

## 物理显示器关闭时

Sunshine 固定捕获 Hyprland 的 `SUNSHINE` 虚拟输出，使用 Wayland screencopy 和 RTX 5090 的 NVENC 编码，不依赖 HDMI/DP 显示器或假显示器插头。它属于现有 Hyprland / Caelestia 会话，是独立的扩展桌面；物理屏幕上的窗口不会被镜像到这里，可通过原有工作区快捷键切换。

Sunshine 随 `hyprland-session.target` 启动，启动和连接时创建/唤醒虚拟屏并将焦点移到它。Caelestia 的闲置息屏和锁屏后息屏只关闭物理输出，保留虚拟屏渲染；锁屏和密码认证仍生效。此方案需要 Axiom 已开机并进入 Hyprland，会话退出、系统休眠或关机时不能串流。

## 中转与端口

```text
Charles Moonlight
  → Acorn 8.159.128.125（Sunshine 原生 TCP / UDP 端口）
  → 独立 frps-sunshine ⇄ QUIC / UDP 7001 ⇄ frpc-sunshine
  → Axiom Sunshine → SUNSHINE 虚拟屏
```

| Acorn 入站 | 用途 |
| --- | --- |
| UDP 7001 | Axiom 到 Acorn 的 FRP QUIC 通道 |
| TCP 47984、47989、48010 | 配对、查询、会话控制 |
| UDP 47998–48000 | 视频、控制、音频 |

独立 FRP 使用 0.71.0、`wireProtocol = "v2"` 和二进制 UDP 消息编码，关闭压缩，校验 Acorn 固定 TLS 证书。QUIC 的底层是 UDP，但 FRP 仍通过可靠流承载 UDP 代理，丢包时可能等待重传，不等同于无重传的原生 UDP 转发。

Sunshine 强制 LAN/WAN 串流加密，避免 FRP 的 localhost 转发被误当作可信局域网。UPnP 关闭，管理端口 47990 不做公网转发。已有 RustDesk 和主 FRP 服务保持独立。

Acorn 实际为上海 ECS，实例名 `aliyun-acorn`；2026-09-14 查得出站带宽上限 100 Mbps、按流量计费。上述五条安全组规则已添加到 `sg-uf644rn49wramiye4gbv`，描述以 `sunshine-` 开头；NixOS 防火墙对应端口已同步。云安全组是单独的云端状态，Nix 切换不会重建这些规则。

## 管理与部署

配置入口：`hosts/axiom/modules/sunshine.nix`、`hosts/acorn/modules/sunshine-relay.nix`、`config/frp/sunshine-relay.nix`。Caelestia 的虚拟屏息屏例外只在 Axiom 启用。

管理页面通过 SSH 转发访问：

```sh
ssh -N -L 47990:127.0.0.1:47990 axiom-tunnel
# 在 Charles 浏览器打开 https://localhost:47990
```

Sunshine 管理用户名为 `c1`。随机管理密码只以 Axiom SSH 公钥加密，保存在 Axiom 的 `~/.config/sunshine/admin-password.age`（0600）；可在 Axiom 使用 `nix shell nixpkgs#age` 取得 age，再以对应 SSH 私钥和 `age -d -i ~/.ssh/id_ed25519 ~/.config/sunshine/admin-password.age` 解密，不将明文写进仓库或日志。配对信息在 `~/.config/sunshine/sunshine_state.json`，不纳入版本控制。

Axiom 和 Acorn 的 NixOS 系统均在 Axiom 构建，Acorn 只接收闭包并激活。正常更新从本分支/合并后的 flake 构建两个 host；不得在 Acorn 编译。部署后若当前 Caelestia 仍运行旧 store 路径，需重新加载 shell；锁屏中更新时要由新 shell 重新执行 `caelestia shell lock lock` 接管锁屏。

```sh
ssh axiom-tunnel 'systemctl --user status sunshine; systemctl status frpc-sunshine'
ssh axiom-tunnel 'hyprctl -i 0 monitors -j'
ssh azar 'systemctl status frps-sunshine'
```

停用时停止 Axiom 的 `sunshine` 用户服务及两端独立 FRP 服务，撤销本次五条云安全组规则，再移除两个 host 的模块导入、对应 Nix 防火墙端口及 Axiom 的虚拟屏配置。确认窗口已移开后可用 `hyprctl output remove SUNSHINE` 删除运行中的虚拟输出。保留 Sunshine 配对数据便于恢复；RustDesk 和主 FRP 不需要停用。

## 2026-09-14 验证

- Axiom / Acorn 完整系统构建及激活成功，FRP 两端配置校验通过，六个代理注册成功。
- Axiom 仅有 `SUNSHINE` 虚拟输出时，公网 Moonlight 配对、HEVC 硬件编解码、持续出画面及主动断开后恢复均成功。
- 锁屏超过 60 秒仍持续串流；对实际构建的 Caelestia 逻辑验证：DP-4/DP-5 继续息屏，SUNSHINE 不息屏，锁定/解锁动作保留。
- 用户通过 Moonlight 实际解锁，并确认鼠标和键盘操作正常。
- 一段约三分钟的客户端记录：60.06 FPS，平均网络延迟 38 ms，网络丢帧 0.00%，抖动掉帧 0.50%，平均主机处理 1.7 ms。这是当时网络的短时结果。
- RustDesk、原 FRP 和 Hyprland 会话均保持运行。音频通道初始化成功，但未做听感测试；物理屏幕重新接入、整机重启和长时间高动态画面尚未实测。

参考：[Sunshine 配置](https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2configuration.html)、[Moonlight 设置](https://github.com/moonlight-stream/moonlight-docs/wiki/Setup-Guide)、[FRP QUIC](https://gofrp.org/en/docs/features/common/network/network/)。
