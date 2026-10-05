# Charles 访问 Axiom 用户文件

Charles 登录后自动把 Axiom 的 `/home/c1` 挂载到 `~/Axiom`。`Work` 是其中的子目录，在 Charles 上通过 `~/Axiom/Work` 访问。使用 macOS 原生 SMB 客户端；Axiom 运行 Samba，不需要 SSHFS 或 FUSE-T。

## 使用

在 Finder 中打开 `~/Axiom`，或运行：

```sh
open ~/Axiom
axiom-files status
```

登录时连接一次；首次连接会等待点对点打洞，实测冷启动约 25 秒。网络尚未就绪时，每 60 秒重试。已有挂载保持当前传输路径，由原生 SMB 处理连接恢复，不在打开文件期间切换服务器地址。

```sh
# 手动连接，并恢复自动挂载
axiom-files connect

# 正常卸载并暂停自动挂载；有文件占用时先关闭相应程序
axiom-files disconnect

# 需要手动换通道时，先正常卸载，再指定传输
axiom-files disconnect
axiom-files --transport frp connect
```

默认连接 FRP XTCP `127.0.0.1:1446`：Ant 协调打洞，文件数据在 Charles 与 Axiom 间点对点传输。XTCP 在 5 秒内无法建立连接时转交 STCP；也可手动选择 WireGuard `10.77.0.2:445` 或 FRP STCP `127.0.0.1:1445`。备用路径的数据经过 Ant，实测性能明显较弱。所有路径均不开放公网 SMB 端口。挂载工具从密文读取专用密码并传给原生 NetFS，用户无需在终端输入密码。

`status` 的 `source` 显示本地接入端口；1446 表示使用 P2P visitor，不能单凭端口断定当前已打洞。是否实际点对点连接，应查看 FRP 的 `establishing nat hole connection successful` 日志；备用转发仍使用同一个接入端口。

## 配置归属

- `hosts/axiom/modules/files.nix`：共享 `/home/c1`，限定 c1 账户，SMB3 与加密必须启用，Apple 元数据扩展，账户由 age 密文自动配置；FRP STCP/XTCP 代理连接本机 Samba。共享名 `work` 保留以兼容现有自动挂载配置。
- `config/wireguard/linux.nix`：Axiom 和 Ant 仅允许 Charles `10.77.0.4` 到 Axiom `10.77.0.2` 的 TCP 445。
- `hosts/charles/modules/axiom-files.nix`：FRP P2P/STCP visitor 和登录挂载 agent；`bin/axiom-files.py` 调用系统 NetFS。
- `hosts/{axiom,charles}/secrets/`：专用 SMB 密码与 FRP 访问密钥的 age 密文。Samba 密码与系统登录密码分开；明文不出现在命令参数或仓库中。

Samba 显式绑定 loopback 和 WireGuard IP，并使用合成 `/24` 掩码避开 Samba 对非广播 `/32` 接口的过滤；系统仍保持原来的 WireGuard `/32` 路由。`fruit` 与 `streams_xattr` 按 [Samba 官方说明](https://www.samba.org/samba/docs/4.23/man-html/vfs_fruit.8.html) 配合使用，目录枚举会携带 Apple 元数据，减少逐个文件的请求。[FRP XTCP](https://gofrp.org/en/docs/examples/xtcp/) 使用专用共享密钥，STCP 备用与控制连接沿用现有 TLS 中转。打洞采用 `stun.miwifi.com:3478`；STUN 只用于发现公网地址，文件内容由 SMB3 加密。

`config/axiom-files-network.nix` 和 `bin/axiom-files-network.py` 在 Home Manager 激活时为两端 Clash Verge 的全局 Script.js 追加 FRP DIRECT 规则，并同步到生成的 `clash-verge.yaml`，通过已有本机 Unix API 载入。Charles 的挂载 agent 每 60 秒也会检查该规则，已有挂载时仍能修复缺失的规则；手动暂停自动挂载后暂停检查。保留原有脚本、其他规则和订阅；首次写入留存 `Script.js.pre-axiom-files` 和 `clash-verge.yaml.pre-axiom-files`，权限为 600。这条规则要求 Clash 处于 rule 模式，避免 STUN 与点对点数据走海外代理。后续 Verge 生成配置时仍会应用该规则。回退时删除脚本标记块及生成配置中的专用 FRP 规则，再让 Verge 重新生成配置；恢复备份前需确认没有覆盖之后的用户修改。

## 排查与撤回

```sh
axiom-files status
smbutil statshares -m ~/Axiom
launchctl print gui/$(id -u)/org.nixos.frpc
tail -20 ~/Library/Logs/axiom-files.log
tail -20 ~/Library/Logs/axiom-files-frpc.log
```

期望 `SMB_VERSION=SMB_3.1.1`、`ENCRYPTION_REQUIRED=TRUE`，并显示当前加密算法。SMB 内层加密让 Ant 只转发密文。

回退先运行 `axiom-files disconnect`，再移除两个 host 的 files 模块 import 和对应 WireGuard 445 规则，按正常 Nix 流程构建、switch。保留 Axiom 的用户目录；无需删除文件。旧系统 generation 可用于恢复，重新启用 SMB 时保留加密凭据。

为保证 Axiom 本地程序修改文件后 Charles 能看到新内容，启用了 Linux kernel oplocks，并关闭不协调本地写入的 SMB leases；该选择依据实际一致性测试和 [Samba 文档](https://www.samba.org/samba/docs/4.23/man-html/smb.conf.5.html#KERNELOPLOCKS)。网络卷仍受广域网延迟影响。大型构建、依赖安装和全仓库搜索宜在 Axiom 本地执行。

已有 Linux 符号链接可以读取；测试中从 Mac 新建的 SMB 链接未成为 Linux 原生 symlink。因此 Linux 构建所需链接应在 Axiom 创建，尤其是依赖安装目录。项目文件按大小写区分。原生目录通知已做 kqueue 测试，但各编辑器的监视与重连策略还取决于应用自身。当前性能和验收记录见 [部署与测试报告](../.legion/tasks/charles-axiom-files/docs/verification.md)。
