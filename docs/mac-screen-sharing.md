# Charles 连接 Charlie：Apple 屏幕共享

Charles 使用 Apple 普通屏幕共享，经 Ant 的 FRP 私有 STCP 通道访问 Charlie。FRP 网络段采用 QUIC（UDP 7001）。屏幕共享配置不修改 Charlie 的实体显示器分辨率。

## 使用

在 Charles 运行 `~/.local/bin/charlie-screen`（完整 nix-darwin 激活后也可直接运行 `charlie-screen`），或在屏幕共享 App 中连接 `vnc://127.0.0.1:15900`，使用 Charlie 的 `c1` 账户登录。选择普通屏幕共享模式。连接命令会先检查远端的 RFB 握手，通道不通时给出错误。

连接路径：

```text
Charles Screen Sharing → 127.0.0.1:15900 → Charles frpc visitor
  → Ant frps 106.15.156.143:7001（QUIC/UDP）→ Charlie frpc → 127.0.0.1:5900
```

- Charles 的 `org.nixos.frpc` 是用户级 LaunchAgent，在 `c1` 登录后启动。
- Charlie 的 `org.nixos.frpc` 是以 `c1` 运行的系统级 LaunchDaemon，不依赖 GUI 登录会话。
- Charlie 屏幕共享访问名单仅包含 `c1`。现有 SSH 反向隧道保持独立。
- Ant 不公开监听 VNC 5900。两端 frpc 校验仓库中的 Ant TLS 证书及服务器 IP，并使用独立 STCP 密钥和通道加密。
- 屏幕共享本身仍是 TCP 普通模式。Apple 高性能模式另需 UDP 5900–5902 互通；FRP 改用 QUIC 不会自动启用该模式。

## 分辨率

Charlie 保留用户选择的显示模式。2026-09-16 复核为 HiDPI：界面尺寸 2560×1440、渲染尺寸 5120×2880、60 Hz；渲染尺寸不代表显示器面板的原生分辨率。

此前的 `charlie-screen-resolution` 和登录任务直接改变了实体显示器的模式，不符合只调整远程画面的要求，已撤除。当前普通屏幕共享连接不支持动态分辨率；本配置没有实现独立于实体显示器的远程分辨率限制。

## 配置与密钥

公共 FRP 模块为 Linux 保留 systemd 服务，为 Darwin 提供系统守护进程和用户代理。Mac 客户端启动时使用自己的 SSH identity 解密 agenix 清单中的密文，在内存中完成替换，再原子写入权限为 `0600` 的运行配置；父目录权限为 `0700`。不依赖异步的全局 agenix 作业先完成，解密失败时不会启动 frpc。运行配置位于 `~/Library/Application Support/frpc/frpc.toml`，包含凭据，不应输出或分享。

`modules/agenix.nix` 将密文文件声明为 Nix path，使独立构建的 launchd 闭包也实际包含所需密文；原先的字符串路径会产生未登记的源目录引用。

密钥分工：

- 延续已经部署的 FRP token；两台 Mac 和 Ant 各自只持有为自身 SSH identity 加密的凭据。
- `screen-sharing-key.age` 是两台 Mac 共享的独立随机通道密钥。
- Ant 的 `frps-tls-key.age` 只授予 Ant 解密。公开证书是 `config/frp/ant-frps.crt`，SAN 为 `106.15.156.143`，有效期至 2036-09-12；更换证书时需同步更新两台客户端的信任配置。
- Mac 密文更新后需要重新构建并加载对应 frpc plist；新密文路径会改变服务脚本，常规 nix-darwin 激活会重载服务。

## 构建与部署

本次只部署 Mac 屏幕共享相关产物。Ant 的 `frps-sunshine` 是已经在运行的 QUIC 服务，本变更补齐其源码声明，并保留已有 Sunshine 端口、二进制版本和凭据。没有重新部署 Ant，也没有纳入 Acorn、SSH 跳板和 Axiom 的整批迁移。

Ant 其余中转已在后续迁移中补齐并完成原生部署，见 [迁移记录](ant-relay-migration.md)。Ant 和 Acorn 均不执行构建。

Mac 可以独立构建本次相关的产物：

```sh
nix build .#darwinConfigurations.charles.config.system.build.launchd
nix build .#darwinConfigurations.charles.config.system.build.screenSharingTools
nix build .#darwinConfigurations.charlie.config.system.build.launchd
nix build .#darwinConfigurations.charlie.config.system.build.screenSharingTools
```

以下为 2026-09-14 首次部署记录，当时中转为 Acorn：只安装 Charles 用户级 frpc plist、Charlie 系统级 frpc 和更新后的 agenix plist，以及连接工具，没有切换两台 Mac 的完整系统 generation。原因是当前整机 generation 与仓库基线之间还有无关的开发工具变化。相关产物已注册 GC roots，plist 持久安装在各自的 `Library/LaunchAgents` / `/Library/LaunchDaemons`，与本次声明一致；后续完整 nix-darwin 激活可接管这些服务。

Charlie 的屏幕共享已通过 SSH 启用，组成员和 launchctl override 持久保存；host 模块中的激活步骤会维持该设置。这里的成功依据是本机实测，不将该办法泛化为所有 macOS 版本都支持的开启方式。

## 检查

```sh
# Charles
launchctl print "gui/$(id -u)/org.nixos.frpc"
tail -n 20 ~/Library/Logs/frpc.log

# Charlie，通过现有 SSH 入口
ssh charlie 'launchctl print system/org.nixos.frpc'
ssh charlie 'nc -G 3 -z 127.0.0.1 5900'
```

错误日志位于 `~/Library/Logs/frpc-error.log`。Ant 服务为 `frps-sunshine`；单看应用连接 localhost TCP 15900 不能判断中转协议，需要核对当前 frpc 的 UDP socket 和两端到 Ant:7001 的实际流量。

## 初次迁移的 RustDesk 退役与回滚

新通道通过账户认证和图像传输验证后，才运行 Charlie 的 `retire-charlie-rustdesk`。它只处理带仓库 ownership marker 的安装，停止三个旧作业，将 App、plist、provisioning 状态和 marker 移入 `/var/db/mac-screen-sharing/rustdesk-backup`，不覆盖已有备份。用户的其他 RustDesk 数据不作批量删除。

回滚时先确认 SSH 可用，再以管理员权限把备份中的 App 放回 `/Applications/RustDesk.app`，把三个 plist 分别放回原来的 LaunchDaemons / LaunchAgents 目录；恢复 marker 和 provisioning 状态，加载系统作业及 `gui/<c1 UID>` 的 server 作业。若恢复旧声明式配置，从本次 PR 之前的 Git revision 恢复 Charlie 的 RustDesk 配置与密码密文。备份保留旧系统 GC root，避免旧作业依赖在后续系统切换后被回收。

可以先保留 FRP 通道帮助诊断；停止它不影响独立的 SSH 反向隧道。切换中转服务器时需同步调整 Mac 的地址、端口、协议和信任证书。

## 2026-09-15 试用结果

- 原模式：界面 2560×1440、渲染 5120×2880；试用曾将实体显示器切换为非 HiDPI 的 2560×1440、60 Hz，随后按用户要求撤回。
- 两端实际流量确认 QUIC/UDP 到 Ant:7001，Clash 策略为 DIRECT；原入口 localhost:15900 可用。
- 两端 frpc 重启后恢复，屏幕共享实际锁屏画面可见；临时探测配置已清理。
- 用户试用反馈流畅度明显改善。
- 12 组交替 RFB 握手测试的中位耗时：TCP 47.0 ms，QUIC 54.1 ms。这不是画面延迟测试，也不能用来声称 QUIC 降低了基础延迟。分辨率和传输均有改变，主观改善不能单独归因于其中一项。

## 2026-09-16 QUIC 部署与分辨率纠正

- Charles、Charlie 的 `system.build.launchd` 在 Charles 构建通过；FRP 配置渲染及 age 集成测试 9 项通过。
- 两台 Mac 替换了 `org.nixos.frpc`；现有 AutoSSH 和其他作业未部署或替换。两个 launchd 产物均注册在各机 `~/.local/state/mac-screen-sharing/launchd` GC root。
- 安装后的 plist 与构建产物字节一致，FRP 使用原生 Nix 启动脚本，已接替临时的配置补丁脚本。
- 已卸载并移除误装的 `org.nixos.screen-sharing-resolution` 登录任务，同时删除对应源码和构建目标。读回的显示模式与试用前记录一致：界面 2560×1440、渲染 5120×2880、60 Hz。
- Ant 整机 derivation 求值通过；QUIC 服务的二进制和配置路径与当前运行实例一致，两项密文使用 Ant 现有主机密钥解密验证通过。Ant 未构建或切换系统。
- QUIC 部署时复核了普通屏幕共享实际连接和两端 QUIC/UDP。分辨率纠正未重启 frpc；未注销或重启机器，不将其当作 FileVault 冷启动测试。

回退本次 Mac FRP 部署时，分别卸载对应 frpc 作业、恢复各机 `~/.local/state/mac-screen-sharing/before-nix-frpc.plist` 并重新加载；这份备份保留之前已经验证的 QUIC 试用配置。不要恢复已撤除的分辨率登录任务。

## 2026-09-14 首次部署验证记录

| 检查 | 结果 |
| --- | --- |
| 密钥渲染单元与 age 集成测试 | 9 项通过；包含转义、权限、缺失/错误密文、轮换和输出符号链接 |
| Charles / Charlie | 整机 derivation 求值通过；相关 launchd 闭包和命令工具构建通过 |
| Acorn | 完整系统在 Axiom 构建、复制并切换成功；Acorn 未进行构建 |
| 正式 STCP 路径 | Apple 账户认证返回成功；服务器报告 5120×2880，实际取得 66×66 像素数据 |
| 错误 STCP 密钥 | 无法取得 RFB 访问 |
| TLS | 固定证书/IP 验证通过；错误服务器身份被拒绝 |
| 自动恢复 | 两端 frpc 收到 SIGTERM 后由 launchd 自动恢复，再次认证和获取图像成功 |
| 回归 | Axiom frpc/RustDesk 和 Acorn frps/RustDesk 均 active；Acorn 无新增 VNC 监听 |
| Charlie 退役 | 三个旧作业停止、受管 App 移出 Applications；SSH 和屏幕共享仍可用 |

整机 Mac 构建曾启动，但包含与本次改动无关的开发工具构建，已主动停止；未将其记为构建通过，也未切换 Mac 整机 generation。

## 验证边界

首次部署验证覆盖账户认证、实际 framebuffer 数据、通道密钥和 TLS 身份拒绝、客户端重启恢复、闭包及运行文件权限。后续试用有用户主观流畅度反馈；中文输入、快捷键、剪贴板和 FileVault 冷启动首次解锁仍未系统测试。Charlie 启用了 FileVault；锁屏后可连接与冷启动首次解锁不是同一种情况。

参考：[FRP 私有 STCP](https://gofrp.org/en/docs/examples/stcp/)、[Apple 高性能屏幕共享要求](https://support.apple.com/en-kw/guide/remote-desktop/apdf8e09f5a9/mac)、[Apple 屏幕共享设置](https://support.apple.com/zh-cn/guide/mac-help/mh11848/mac)。
