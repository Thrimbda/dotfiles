# Charlie SSH 自动选路验证报告

日期：2026-07-30（Asia/Shanghai）

## 验证范围与方法

设计真源是用户批准的“同一台 charlie、LAN 优先、失败时经反向隧道、
`charlie-tunnel` 强制走隧道、最终使用独立 forwarding-only 账户”的方案，
以及本次 diff。执行计划保存在会话临时文件
`/private/tmp/charlie-ssh-plan.md`；它不作为可移植证据，下面所有判定均映射到
repo 内 locator。

本次选择最低成本但能直接证明行为的方法：

- 对客户端路由使用 `ssh -G`、实际 SSH 登录、故障地址模拟和 SCP；
- 对 host key 探针同时覆盖匹配和陈旧地址反例；
- 对隧道权限使用实际命令通道和未批准 `-R` 负测试；
- 对声明式配置使用 Nix 求值，并在 charlie 构建完整 Darwin closure；
- 对运行态使用 `launchctl`、`ps`、`lsof` 和跳板机 listener 观察。

这是常规 OpenSSH/Nix 运维验证，不需要领域签署或外部权威。OpenSSH 当前文档
仅用于确认选项语义，不代替运行证据。

## Claim 登记与状态

| claim-id | 单一主张与验收/风险关系 | 三轴（性质/时机/门槛） | domain-id / capability / method | 原始证据要求 | criticality / risk-if-wrong / blocking-policy / owner | 状态与证据 |
|---|---|---|---|---|---|---|
| C1 | `ssh charlie` 在 pinned key 匹配时选 LAN，探针失败时选隧道；对应自动选路验收 | objective / now / routine | n/a / OpenSSH 配置与网络观测 / `ssh -G`、反例地址、实际登录 | 两种最终配置和 LAN 登录 | high / 误连错误主机或无法回退 / block-stage / c1 | PASS；`docs/evidence/charlie-ssh-live.txt` E1-E3 |
| C2 | `ssh charlie-tunnel` 当前可经 2222 登录同一台 charlie；对应强制逃生入口验收 | objective / now / routine | n/a / SSH 端到端 / 强制 ProxyJump 登录 | 当前实际登录结果 | high / 外网时完全失联 / block-stage / c1 | FAIL；停临时重连前曾 PASS，但当前新连接在 jump banner 阶段失败；E2 与 blocker B1 |
| C3 | 两条路径共用 pinned `HostKeyAlias charlie`，LAN 只有 key 匹配才选中；对应错误主机风险 | objective / now / routine | n/a / host key 比较 / `ssh-keyscan` 与 known_hosts 比较、陈旧地址反例 | 匹配成功、错误/不可达失败 | critical / host impersonation / block-stage / c1 | PASS；live E1-E3 |
| C4 | 最终 `tunnel-charlie` 账户不能开 session、本地 forwarding 或未批准 listen；对应最小权限验收 | objective / now / routine | n/a / sshd 权限与负测试 / staged key 负测试、最终账户实测 | session/local forward/错误 listen 均失败 | critical / 跳板账户成为通用代理或 shell / block-stage / c1 | INCONCLUSIVE；staged key 的 session 与错误 listen 已拒绝，最终系统账户尚未激活，本地 forwarding 最终实测缺失；live E4、nix N2、blocker B2 |
| C5 | 最终反向端口只监听 `127.0.0.1:2222` 且公网防火墙不开放 2222；对应暴露面验收 | objective / now / routine | n/a / listener 与 firewall / `ss`、Nix firewall 求值 | final listener + firewall | critical / 目标 SSH 暴露公网 / block-stage / c1 | INCONCLUSIVE；现有和 staged listener 均为 loopback、最终 Nix firewall 已移除 2222，但最终 closure 未激活；live E4、nix N2、blocker B2 |
| C6 | 相关 Nix 配置可求值，charlie 产出可激活 closure；对应可部署性验收 | objective / now / routine | n/a / Nix evaluation/build / `nix eval`、`nix build`、`nix path-info` | acorn/charles 求值与 charlie build | high / 激活时失败或配置未纳入 / block-stage / c1 | PASS；nix N2-N4。charles 全量 closure 下载被有意中止，不作为 PASS 依据 |
| C7 | 专用路径通过前不退休旧 2222 tunnel；对应无中断迁移边界 | objective / now / routine | n/a / process state / `launchctl`、`lsof` | old tunnel active, staged retry stopped | high / 远程访问中断 / block-stage / c1 | PASS；live E5 |
| C8 | charles 当前已安装 route probe、SSH fragment 和 pinned alias；对应客户端交付 | objective / now / routine | n/a / filesystem + SSH / file mode、`ssh -G`、实际登录 | managed file evaluation + live behavior | high / 用户命令未生效 / block-stage / c1 | PASS；nix N4、live E1-E3 |

## 执行记录与证据映射

- 客户端、正反例、端到端 SSH/SCP、临时权限负测试、旧隧道保护：
  `docs/evidence/charlie-ssh-live.txt`。
- Nix 求值、charlie closure、客户端 managed-file 求值和当前 OpenSSH 文档语义：
  `docs/evidence/charlie-ssh-nix.txt`。
- 跳板机当前不可达、sudo 门和恢复顺序：
  `docs/evidence/charlie-ssh-blocker.txt`。

所有持久化证据均已脱敏：未写入私钥、密码、完整个人数据或 token。未跟踪文件
`acorn_id_ed25519` 未被加入 Git，也未被复制到用于 Nix 的白名单临时源码树。

## 领域 verifier

不适用。所有 claim 都是 routine OpenSSH/Nix 行为，可由静态求值和直接运行观测
支持。未使用模型信心或代理共识代替领域证据。

## Authority evidence

不适用。没有需要资质、签署、审计或外部权威确认的验收主张。

## DEFERRED 与 RECOMMENDATION

无。最终账户验证没有被合同允许延后，因此记为 `INCONCLUSIVE`，不伪装成
`DEFERRED`。本报告也不使用判断性 `RECOMMENDATION` 满足客观验收。

## 独立性、置信度与反例

- C1/C3/C8：独立性 high（由客户端真实 OpenSSH 计算与登录产生），置信度 high；
  主动反例为陈旧地址和 TEST-NET 故障地址。失效条件是 charlie host key、LAN
  保留地址或 include 顺序改变。
- C2：独立性 high，置信度 high；当前失败由三个来源路径的新 SSH banner timeout
  和 HTTPS timeout 共同支持。失效条件是跳板机服务恢复，恢复后必须重测。
- C4/C5：源码/临时测试独立性 medium，最终运行结论置信度 low；缺口是 final
  closure 未激活。不能从 staged c1 key 推断最终 system account 已生效。
- C6：独立性 high，置信度 high；charles 全量 closure 未完成，但 scoped client
  文件求值与 live deployment 已分别覆盖声明和行为。
- C7：独立性 high，置信度 high；旧 autossh/ssh 进程和 TCP 均仍存活。

## 失败、跳过与残余不确定性

- 8.159.128.125 当前接受 TCP 连接但不返回 SSH banner，HTTPS 也超时；无法继续
  build/activate/cleanup。
- 两台目标机的 `sudo -n` 均要求用户交互输入密码；agent 未索取或保存密码。
- jump host 上用于 staged 2226 的临时 restricted authorized_keys 行尚未清理。
  对应 LaunchAgent 已停止，因此当前没有 2226 重连进程；恢复管理入口后必须清理。
- 旧 2222 tunnel 被刻意保留。它继续使用一般 `c1` 登录，直到最终专用账户通过
  全部负测试；这符合无中断边界，但不是最终安全状态。
- charles 全量 Nix closure 因需下载 1176.36 MiB 非相关依赖而中止；不影响已完成
  的 scoped 求值和 live 测试，但后续常规系统 rebuild 仍会拉取这些依赖。

## Verdict

FAIL

C2 当前失败，C4/C5 是核心验收的 `INCONCLUSIVE`，故阶段不能 PASS。源码、客户端
自动 LAN 路由、host key 防误连、专用 key 和可激活的 charlie closure 已准备好；
仍不得宣称最终 forwarding-only 生产路径完成。

## 会话注意力摘要

- 阶段：verify-change
- 阶段结论：FAIL
- 注意力等级：decide
- 判断变化：8.159.128.125 的新 SSH/HTTPS 连接在验证期间停止响应；最终系统账户
  无法激活，旧 tunnel 必须继续保留。
- 关键发现：
  1. 自动 LAN 选路、pinned host key 和实际直连已通过。
  2. staged 专用 key 拒绝 command channel 和未批准 listen，但不能代替最终账户实测。
  3. 旧 2222 tunnel 仍为 ESTABLISHED；临时 2226 重连 Agent 已安全停止。
- 阻塞项：恢复 8.159.128.125 的管理入口，并完成需要用户密码的两端激活。
- 残余风险：临时 restricted 2226 authorized_keys 行尚在 jump host；旧生产 tunnel
  仍使用一般 `c1` 账户。
- 人类动作：在云控制台或带外管理中恢复 8.159.128.125 的 SSH 可达后，只需告知
  “跳板机已恢复”；不要手动停止当前旧 2222 tunnel。
- 自动下一步：等待人类决定；恢复后重跑 verify-change，从 acorn build/activate
  开始，随后由用户本人在 sudo 提示中输入密码并完成最终切换与清理。
- 完整证据：`docs/test-report.md`；
  `docs/evidence/charlie-ssh-live.txt`；
  `docs/evidence/charlie-ssh-nix.txt`；
  `docs/evidence/charlie-ssh-blocker.txt`。
