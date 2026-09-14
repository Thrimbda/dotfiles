# Charles 连接 Charlie：Apple 屏幕共享

Charles 使用 Apple 自带屏幕共享，经 Acorn 的 FRP 私有 STCP 通道访问 Charlie。Axiom 的 RustDesk，以及 Acorn 的 RustDesk signal/relay、密钥、防火墙和中转补丁继续保留。Charles 仍可用现有 RustDesk 客户端访问 Axiom。

## 使用

在 Charles 运行 `~/.local/bin/charlie-screen`（完整 nix-darwin 激活后也可直接运行 `charlie-screen`），或在屏幕共享 App 中连接 `vnc://127.0.0.1:15900`，使用 Charlie 的 `c1` 账户登录。选择普通屏幕共享模式。连接命令会先检查远端的 RFB 握手，通道不通时给出错误。

连接路径：

```text
Charles Screen Sharing → 127.0.0.1:15900 → Charles frpc visitor
  → Acorn frps 8.159.128.125:7000 → Charlie frpc → 127.0.0.1:5900
```

- Charles 的 `org.nixos.frpc` 是用户级 LaunchAgent，在 `c1` 登录后启动。
- Charlie 的 `org.nixos.frpc` 是以 `c1` 运行的系统级 LaunchDaemon，不依赖 GUI 登录会话。
- Charlie 屏幕共享访问名单仅包含 `c1`。现有 SSH 反向隧道保持独立。
- Acorn 不新增公开 VNC 监听端口。两端 frpc 都校验仓库中的 Acorn TLS 证书及服务器 IP，并使用独立 STCP 密钥和通道加密。
- 本方案只承诺 TCP 普通模式。高性能模式另需 UDP 5900–5902 互通及带宽、延迟验证，不能由一次 TCP 连接成功推断。

## 配置与密钥

公共 FRP 模块为 Linux 保留 systemd 服务，为 Darwin 提供系统守护进程和用户代理。Mac 客户端启动时使用自己的 SSH identity 解密 agenix 清单中的密文，在内存中完成替换，再原子写入权限为 `0600` 的运行配置；父目录权限为 `0700`。不依赖异步的全局 agenix 作业先完成，解密失败时不会启动 frpc。运行配置位于 `~/Library/Application Support/frpc/frpc.toml`，包含凭据，不应输出或分享。

`modules/agenix.nix` 将密文文件声明为 Nix path，使独立构建的 launchd 闭包也实际包含所需密文；原先的字符串路径会产生未登记的源目录引用。

密钥分工：

- Acorn 的既有 FRP token 为两台 Mac 各自重新加密，未轮换现有 token，因此不要求 Axiom 更换凭据。
- `screen-sharing-key.age` 是两台 Mac 共享的独立随机通道密钥。
- `frps-tls-key.age` 只授予 Acorn 解密。公开证书是 `config/frp/acorn-frps.crt`，SAN 为 `8.159.128.125`；需在到期前重新签发并同步更新两台客户端的信任证书。
- Mac 密文更新后需要重新构建并加载对应 frpc plist；新密文路径会改变服务脚本，常规 nix-darwin 激活会重载服务。

## 构建与部署

常规部署使用合并后的 flake。Acorn 只能在 Axiom 构建，再将闭包复制到 Acorn 切换，禁止在 Acorn 编译。

Mac 可以独立构建本次相关的产物：

```sh
nix build .#darwinConfigurations.charles.config.system.build.launchd
nix build .#darwinConfigurations.charles.config.system.build.screenSharingTools
nix build .#darwinConfigurations.charlie.config.system.build.launchd
nix build .#darwinConfigurations.charlie.config.system.build.screenSharingTools
```

2026-09-14 的部署只安装 Charles 用户级 frpc plist、Charlie 系统级 frpc 和更新后的 agenix plist，以及连接工具，没有切换两台 Mac 的完整系统 generation。原因是当前整机 generation 与仓库基线之间还有无关的开发工具变化。相关产物已注册 GC roots，plist 持久安装在各自的 `Library/LaunchAgents` / `/Library/LaunchDaemons`，与本次声明一致；后续完整 nix-darwin 激活可接管这些服务。

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

错误日志位于 `~/Library/Logs/frpc-error.log`。Acorn 服务级 FRP 流量统计仍有效；现有逐代理采样只查询 TCP 代理，未增加 STCP 逐代理统计。

## RustDesk 退役与回滚

新通道通过账户认证和图像传输验证后，才运行 Charlie 的 `retire-charlie-rustdesk`。它只处理带仓库 ownership marker 的安装，停止三个旧作业，将 App、plist、provisioning 状态和 marker 移入 `/var/db/mac-screen-sharing/rustdesk-backup`，不覆盖已有备份。用户的其他 RustDesk 数据不作批量删除。

回滚时先确认 SSH 可用，再以管理员权限把备份中的 App 放回 `/Applications/RustDesk.app`，把三个 plist 分别放回原来的 LaunchDaemons / LaunchAgents 目录；恢复 marker 和 provisioning 状态，加载系统作业及 `gui/<c1 UID>` 的 server 作业。若恢复旧声明式配置，从本次 PR 之前的 Git revision 恢复 Charlie 的 RustDesk 配置与密码密文。备份保留旧系统 GC root，避免旧作业依赖在后续系统切换后被回收。

可以先保留 FRP 通道帮助诊断；停止它不影响现有 SSH 反向隧道。Acorn 的 TLS 变更需要回滚时应同步调整 Mac 信任配置，不能在客户端保留固定证书后把服务端恢复为随机证书。

## 2026-09-14 验证记录

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

本次验证覆盖账户认证、实际 framebuffer 数据、通道密钥和 TLS 身份拒绝、客户端重启恢复、闭包及运行文件权限。没有通过 GUI 测试中文输入、快捷键、剪贴板、主观流畅度，也没有重启机器测试 FileVault 首次解锁。Charlie 启用了 FileVault；锁屏后可连接与冷启动首次解锁不是同一种情况。

参考：[FRP 私有 STCP](https://gofrp.org/en/docs/examples/stcp/)、[Apple 高性能屏幕共享要求](https://support.apple.com/en-kw/guide/remote-desktop/apdf8e09f5a9/mac)、[Apple 屏幕共享设置](https://support.apple.com/zh-cn/guide/mac-help/mh11848/mac)。
