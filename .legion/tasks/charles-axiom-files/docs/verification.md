# Charles 访问 Axiom 文件：部署与测试

截至 2026-10-05，文件访问方案已经构建，Axiom、Ant、Charles 均已 switch，并通过以下测试。Charles 解锁后的最终 `darwin-rebuild switch` 退出 0，系统 generation 和切换后双向读写已核实。

## 最终路径

Charles 原生 SMB → 本地 FRP XTCP visitor → Charles/Axiom 点对点 QUIC → Axiom Samba `/home/c1/Work`。Ant 协调打洞。SMB 3.1.1 与 AES-128-GCM，`ENCRYPTION_REQUIRED=TRUE`；未安装 SSHFS/FUSE-T。Samba 4.23.10、FRP 0.66.0；Charles macOS 27.0，Linux 26.05。

两端 Clash Verge 全局 Script.js 保留原逻辑，并追加 FRP DIRECT 规则，同步生成配置并保留权限 600 的原文件备份；两端当前为 rule 模式。Charles 每 60 秒检查并修复缺失的规则。客户端首挂载先等待当前 FRPC 进程打洞完成，最多 30 秒；不能凭 1446 端口推断数据路径。锁定版本的 FRP 日志用于该判定，升级 FRP 时需重新验证。两端当前 NAT 可打洞，换网络后不能保证相同结果。

## 结果

测试只使用 `/home/c1/Work/.axiom-files-test-20261003` 中本任务创建的数据。64 MiB 下载与上传均验证 SHA-256，上传包含 fsync。

| 检查 | 结果 |
| --- | --- |
| 两轮完整原生 SMB 64 MiB 下载 | 9.377 / 14.883 秒，哈希正确 |
| 两轮 64 MiB 上传 + fsync | 16.824 / 18.872 秒，Axiom 哈希正确 |
| 128 个名称枚举 | 0.237 / 0.281 秒 |
| 128 个 stat | 4.515 / 4.536 秒 |
| 24 个 4 KiB 小文件读取 | 2.374 / 2.651 秒 |
| 十次原子保存 | 中位数 446.6 / 459.5 ms；末轮最大 498.9 ms |
| Axiom 本地写入在 Charles 可见 | 0.125 / 0.097 秒 |
| 中文、大小写、已有 Linux 链接、FinderInfo | 通过 |
| Mac 写入在 Axiom 可见、截断与读回 | 通过 |
| Emacs batch 原生 UTF8 保存与读回 | 通过，未加载用户 Emacs 配置 |
| 冷启动，FRPC 故意延迟一秒启动 | 25.278 秒后选择已打洞路径；首轮 STUN 失败后重试成功 |
| 最终客户端原生读 64 MiB 的路径对照 | 10.772 秒（含前后采样），Ant 总 TX 增量仅 208,860 字节，文件哈希正确 |
| 隔离 XTCP 不可用 → STCP 备用 | 5.502 秒读回认证加密小文件；未证明备用大文件可靠 |
| FRPC 暂停五秒后恢复 | 只读操作 5.355 秒完成，内容正确；未模拟整机睡眠 |
| 匿名与 SMB2 不加密连接 | 被拒绝；认证加密连接成功 |
| Nix assertions / Python 编译 / diff whitespace | 无失败 |
| 2026-10-05 Charles 整机 switch 后双向 2 MiB | 下载 1.123 秒，上传 + fsync 1.047 秒，两端 SHA-256 正确；测试文件已清理 |

Ant 出方向计数增加不到文件大小的 1%，结合真实公网端点打洞日志，支持该次文件数据绕过 Ant。计数是整机总量，包含其他服务流量，并非逐流精确计费。

早期默认 SMB leases 导致 Axiom 本地修改在 Mac 超过 15 秒仍旧缓存；最终启用 kernel oplocks、关闭 leases。大小写区分已修正。Mac 创建的 SMB 链接并非 Linux 原生 symlink；Linux 依赖目录和构建所需链接应在 Axiom 创建。

WireGuard 与纯 STCP 的完整大文件测试出现严重慢速或 ENXIO，均未作为顺畅主路径验收。独立 Ant→Charles SSH 对照也慢：空闲 4 MiB 分别 34.625 秒（BBR）与 35.197 秒（CUBIC）；已恢复 BBR。Ant CPU、内存和本地队列无拥塞。云 API 核实 Ant 套餐峰值 200 Mbps；[阿里云说明](https://help.aliyun.com/zh/simple-application-server/product-overview/limits)强调峰值不作带宽承诺，不能据此断定本次丢包的具体来源。

## 当前部署状态与收尾

- Axiom：最终 Samba、STCP/XTCP、DIRECT hook 已 switch，系统 `l9jz843bdrhai28b5d356yy629cis1bk`；switch unit `Result=success`、`ExecMainStatus=0`。Samba、FRPC、`wg-quick-wgdesk` 正常，仅监听 loopback/WireGuard 445；switch 后原生挂载读取通过。10 月 4 日无 failed units，10 月 5 日发现一条 systemd-coredump 的 OOM 失败记录，未重置该状态，文件服务正常。
- Ant：定向 445 转发已 switch，系统 `nalhqya72a7nqcx5wsvk2g87kiz78vy7`；既有中转服务保留。
- Charles：最终整机 switch 退出 0，当前系统与 system profile 均为 `9my6b2cdx1fi5vj1hxdzj36qym79zyl2`；两个 user LaunchAgent 已载入，挂载 agent 最近退出 0，`~/Axiom` 已挂载，自动挂载未暂停。系统命令、agent 均使用最终构建；专用 pending-system GC root 已移除。
- Git：本任务使用隔离分支 `codex/axiom-files` 交付，主工作区原有改动保留；提交与合并状态以 GitHub PR 为准。

部署快照保留此前的 Codex 和可写 SSH 修改，但它们不进入本次 PR。

本任务的远端测试目录、两端临时 FRP 配置和临时代理 YAML 已清理，测试进程已退出；结构化结果保留在下方记录中。

仍未验证：真实睡眠唤醒、整机重启、其他 NAT 环境和 Finder 界面交互。广域网逐文件扫描仍慢；大型构建、依赖安装和全仓库搜索安排在 Axiom。本报告不承诺中转备用路径达到点对点性能。

原始结构化结果见 [results.json](results.json)。
