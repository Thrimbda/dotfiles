# Charles 访问 Axiom 文件 — Context

## 2026-10-03 实施授权与设计

用户要求尽可能顺畅，允许操作相关电脑、安装软件和调整 dotfiles，并要求 switch 后提交合并 PR。此前调查方案获批。独立 worktree `/Users/c1/.codex/worktrees/axiom-files/dotfiles`，分支 `codex/axiom-files`，基于 `167f3e82`。

已核对三台主机身份；Axiom、Charles sudo 需要密码，Ant 免密码。WireGuard 正常；两条 445 定向策略缺失；Axiom 未运行 SMB。SOPS 凭据仅经内存及 stdin 消费。既有 Codex 和可写 SSH 改动需加入临时部署快照保留，但不提交本 PR。

Context7 已执行 Samba library/docs 和 FRP library 共 3 条命令；FRP 细节采用官方 STCP 文档和已核实的 0.66.0 配置。Legion MCP 未提供，直接维护本任务文件。

## 构建与首台切换

声明采用 Samba 4.23.10；原生挂载使用本机 SDK 的 NetFSMountURLSync，包括 NoUI 与 AllowLoopback。四份 age 密文已生成且验证，无明文凭据文件。Charles darwin-rebuild switch 已退出 0，当前系统 a0mgvvwk6vs0d39qq0gsyayl736l4mfr；两个 user LaunchAgent 已载入。Linux 首次源码传输误带 AppleDouble，导致 ._attrs.nix 解析失败；重新用 COPYFILE_DISABLE=1 和 --no-xattrs 传至独立 deploy-clean 后构建通过。Ant 未执行构建。

## 三台初次 switch 与运行时修正

Ant switch 成功，当前 nalhqya72a7nqcx5wsvk2g87kiz78vy7，FRP/WireGuard 正常且仅新增定向 445。Axiom switch 首次 transient unit 中 nix-env 不在 PATH，改用绝对路径后成功，未影响管理连接。SMB 账户和 Samba 正常。FRP 原生挂载 127.0.0.1:1445 已证明 SMB 3.1.1、AES-128-GCM、ENCRYPTION_REQUIRED。匿名及 SMB2 无加密连接被拒绝；认证加密连接成功。

发现 Samba 忽略 WireGuard 非广播接口，显式 /32 仍被当作网络地址而调用同一过滤路径；查阅 Samba 4.23.10 interface.c 后改用私网 IP 的合成 /24，仅影响 Samba 绑定，不改变系统路由或授权。普通 umount 遇到 macOS Resource busy，diskutil 非强制卸载成功，已修正工具；指定传输时也拒绝把已有另一通道的挂载当作成功。初次 benchmark 因 macOS Python 无 os.setxattr 中断，随后一轮因已有 FRP 挂载而标错 WireGuard 被主动中止，这两轮均不计入比较；最终测试将验证 mount source。

## 一致性与目录语义修正

合成 /24 绑定经实际 ss 验证只监听 127.0.0.1 和 10.77.0.2。默认 SMB leases 的测试失败：Axiom 本地写入后重复读取仍旧缓存超过 15 秒。依据官方 kernel oplocks 文档启用 kernel oplocks 并关闭 SMB2 leases 后，inplace 0.3674s、atomic replace 0.3786s 可见，kqueue 目录通知通过。Mac 创建符号链接可用，但 Axiom is_symlink 为 False，因此不能把它视作 Linux 原生链接。另发现 case.txt/Case.txt 混淆，现已设置 share case sensitive=yes，待最终配置验证。主机完整 assertions 的 JSON 会强制求值原本无需展开的成功 message，触发 NixOS cycle missing；改为仅展开失败 message 后 Axiom/Ant 均 []，Charles 263 条断言无失败。

## 最终 WireGuard 压测淘汰

case sensitive=yes 已证明 lower/upper 内容分别正确。最终配置的 WireGuard 64 MiB 下载持续超过 5 分钟；采样 ss 显示 bytes_retrans=3891504、2853 个重传段，后续仍约 10% 重传且速率明显下降。不能以早期 9 秒下载作为稳定性证明，本轮淘汰为默认路径。中止仅针对本任务只读 fixture 下载；Samba 重启后原生客户端重连继续慢速读取，普通卸载失败，针对测试卷 force 卸载后基准进程退出，未进行用户项目写入。FRP 正在最终配置下完成整套测试；按结果决定主路径。

## 大文件继续调查

FRP 在未限制多通道、以及限制多通道后的完整测试都于大文件读阶段失败 ENXIO/坏文件描述符，不能认定 FRP 已通过。没有 smbd 主服务崩溃或 failed unit。Linux 本机加密 smbclient 完整读取 64 MiB 成功（约 923041 KiB/s，仅 loopback，非 WAN 性能）。下一版本限制 SMB read/write 为 1 MiB，并在 NetFS 请求 ForceNewSession，防止旧会话干扰。必须完成最终测试再提交合并；尚未承诺最终主路径。

## 网络瓶颈核实

v8 限制读写大小与 ForceNewSession 后仍在大文件读阶段失败。独立 SSH 对照也慢：Ant→Charles 8 MiB 104.97s；空闲 4 MiB BBR 34.625s，CUBIC 35.197s，已恢复 BBR。Ant CPU/内存/CAKE 队列正常，空闲总出方向约 1.6Mbps，无端口或 NIC 计数错误。云 API 核实 Ant 正常、套餐 swas.s.c2m2s40b1.linux、峰值 200Mbps；官方明确峰值不承诺且可能丢包，不能据此断定本次具体原因。考虑绕过中转数据流，正在核实两端公网 IPv6/FRP P2P 可行性，保持既有服务。

## 点对点方案通过临时验收

FRP XTCP 初次打洞经 Mihomo 代理地址 188.253.*，虽成功却慢；为 FRP 添加 PROCESS-NAME,frpc,DIRECT 并使用国内 STUN 后，两端真实公网地址 117.39.* 与 49.75.* 打洞成功。独立加密 smbprotocol 64 MiB 8.594s，SHA256 正确；原生 NetFS 完整 benchmark 通过：names 0.2374s，128 个 stat 4.5145s，24 个小文件 2.3735s，下载 64 MiB 9.3772s，上传+fsync 16.8242s，保存 median 446.6ms，远端本地写入 0.1248s 可见，大小写/中文/已有 Linux 链接/FinderInfo/双向哈希均通过。该证据来自临时 XTCP，最终声明新增默认 P2P 1446、STCP 后备、持久 DIRECT hook；正在构建 v9 和最终配置验证。

Charles 锁屏使 sudo 的系统认证挂起。已要求用户解锁，并清理本任务挂起的 sudo；不修改 PAM 或登录安全设置。未完成最终 switch，不提交合并。

## 最终客户端进一步验收

Axiom v10 switch success/0，当前 smy0yl3a3sjksli3s2674jr1gn67bwb7；Samba 只监听 127.0.0.1/10.77.0.2:445，无 failed units。最终 P2P 主代理另一轮完整 native benchmark 通过：names 0.2813s，stat 4.5361s，download 14.8831s，upload+fsync 18.872s，save median 459.5ms/max498.9ms，remote change0.0969s。Emacs batch 实际保存、读回 UTF8 成功。

隔离的 XTCP missing proxy 测试在 5.502s 通过 STCP 读取认证加密小文件；不代表备用大文件已达标。FRPC 暂停5s后只读操作5.355s完成，内容正确；不等同于睡眠/重启验收。冷启动v11仍被淘汰：端口1446监听后先走了STCP，后来才打洞成功，端口不能证明当前数据路径。v12新增等待当前 FRPC 进程打洞成功的 gate，再开始挂载；正验证。

Charles 整机仍是2kr4vbzy98sfw6phvb5nq9zrcxy6xff1；客户端仅从新构建的 user plist 试运行，尚非最终整机 switch。用户解锁请求仍未响应；不提交合并。

## 最终验收与待解锁恢复点

冷启动 v12 验收通过：FRPC 延迟一秒启动后，挂载等待实际打洞成功，25.278 秒完成。最终原生读取 64 MiB 哈希正确，含 Ant 前后采样 10.772 秒；Ant 整机 TX 只增加 208,860 字节，支持这次数据未经过 Ant。v13 将 DIRECT 同步到生成配置，Charles 自动 agent 每 60 秒在已挂载时也检查规则；保留全局脚本和源配置备份，不改变 Clash rule 模式。最终 Charles assertions []、Python 编译和 whitespace 检查无失败。

Axiom v13 switch Result=success/ExecMainStatus=0，当前 l9jz843bdrhai28b5d356yy629cis1bk；smbd/frpc/wg-quick-wgdesk 正常，无 failed units，只监听 127.0.0.1 和 10.77.0.2:445。switch 后 Charles 原生读取和大小写检查通过，SMB3.1.1/AES128GCM/ENCRYPTION_REQUIRED 再确认。

Charles 最终 v13 系统 /nix/store/9my6b2cdx1fi5vj1hxdzj36qym79zyl2-darwin-system-26.05.c3e90c8 已构建；两个最终 user plist 已持久写入 ~/Library/LaunchAgents 并载入，挂载 ~/Axiom 未暂停。新 axiom-files 为 /nix/store/0ym1xvx8k0n7b8yd023g34l0sam4ddqx-axiom-files/bin/axiom-files。系统仍旧 2kr4vbzy98sfw6phvb5nq9zrcxy6xff1。ioreg 再核实 CGSSessionScreenIsLocked=true；解锁请求 pending，无用户回复，不尝试修改 PAM 或绕过认证。未提交，未建 PR。

本任务远端 /home/c1/Work/.axiom-files-test-20261003、两端诊断 FRP p2p/fallback 目录及 axiom-files-test.yaml 已清理，测试进程已退出。Axiom Mihomo 已恢复 canonical clash-verge.yaml 配置。部署快照、结果、回退备份和 pending-system GC root 保留。

恢复：在本 managed worktree codex/axiom-files 继续。用户解锁 Charles 后，使用私有 /private/tmp/axiom-files-h9qpuyp5/ops.py sudo charles darwin-rebuild switch --flake path:/private/tmp/axiom-files-h9qpuyp5/deploy#charles 完成 switch（此前 sudo 等待 authd，密码不输出）。构建 outlink /private/tmp/axiom-files-h9qpuyp5/charles-result-v13。该快照保留已有 Codex/可写 SSH 用户改动，但提交只使用本 worktree diff。不要重新运行 ops.py secrets 或轮换已部署密文。核对 generation/agents/mount 后，仅删除本任务 ~/Library/Application Support/axiom-files/pending-system GC root，再提交、rebase/push；gh 一律 --repo Thrimbda/dotfiles，创建 PR 后 attach_artifact，squash merge。完成后 archive managed worktree 并安全刷新主工作区；刷新前重新备份用户改动，不能用旧备份覆盖并发修改。

## 2026-10-05 解锁后完成 switch

用户回复“已解锁”，继续既有部署和提交合并授权。核对主工作区运行配置与临时快照一致；未把用户 Codex/可写 SSH 改动加入 PR。Charles darwin-rebuild switch 退出 0，/run/current-system 与 system profile 均为 9my6b2cdx1fi5vj1hxdzj36qym79zyl2，最终 agent 正常，原生挂载未暂停，SMB3.1.1/AES128GCM/强制加密确认。切换后新建唯一测试目录：2 MiB 下载 1.123s、上传+fsync 1.047s，两端哈希正确，目录已清理。仅删除本任务 pending-system GC root。

Axiom/Ant generation 未变化，三项文件/网络服务均正常。Axiom 发现今天 systemd-coredump unit 的 OOM 失败；不改动该状态，不把它误报为文件服务失败或全机无 failed units。origin/master 仍为 167f3e82，开始提交并按用户授权合并。
