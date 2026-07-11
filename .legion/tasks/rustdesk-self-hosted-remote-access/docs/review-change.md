# Review Change：RustDesk 自托管远程访问

> **Verdict**: **FAIL**
> **Gate**: 当前变更不能进入可合并的配置 PR；阻塞项退回 `engineer`
> **Review target**: 配置 PR readiness，不代表生产部署完成
> **Security lens**: **已展开**（secret、crypto identity、root service、public ingress、local IPC/argv、mutable app trust boundary）
> **Reviewed**: 当前 worktree 的全部变更，以及 `plan.md`、`docs/rfc.md`、最终 PASS 的 `docs/review-rfc.md`、最新 PASS 的 `docs/test-report.md`
> **Secret boundary**: 未读取或解密任何 secret plaintext，未读取主工作区凭据；本报告不包含 ciphertext、public-key value、fingerprint、digest 或其他 secret-derived value
> **Date**: 2026-07-11

## 1. Decision

**FAIL**。Acorn/Charlie 的主体实现大体符合 RFC，且 DNS、Aliyun SG、TCC、Wayland、真实 launchd/StateDirectory 行为仍应保留为部署阶段 gate；但当前 Axiom provisioning 存在确定的 systemd 自重启问题，NixOS secret-bearing 进程还存在未封闭的持久化 coredump 路径。因此现在不能给出 **PASS for config PR**，也不得部署。

修复阻塞项后必须重新进入 `verify-change`，补齐 Darwin build/signature 与 secret ceremony 的非秘密证据，再重新执行 `review-change`。

## 2. Blocking findings

### HIGH — B1：Axiom provision 会因 `Requires=` 传播而重启/终止自身

- **位置**：`hosts/axiom/default.nix:377`，`hosts/axiom/default.nix:580-584`
- **证据**：`rustdesk-provision.service` 对 `rustdesk.service` 同时声明 `Requires=` 与 `After=`；其正在运行的 `ExecStart` 又执行 `systemctl restart rustdesk.service`。锁定系统的 `systemd.unit(5)` 明确规定：被 `Requires=` 的 unit 被显式 restart 时，依赖方也会被 stop/restart。
- **影响**：provision shell 会在 password 已设置、但 post-restart public check 和 stamp commit 尚未完成时被 systemd 终止或重启。最坏情况下形成“注入 password → restart root service → provision 自身 restart → 再注入”的循环；Axiom 没有 Charlie 的持久 attempt budget，因此会扩大 plaintext argv window，并可能永远无法写入成功 stamp。
- **最小修复方向**：不要让会主动 restart `rustdesk.service` 的 provision unit `Require=` 它。改为不会传播 restart 的启动/排序关系（例如 `Wants=` + `After=`），或重新拆分 restart/verification 拓扑；仍须在脚本内 fail closed 地检查 service/IPC readiness。增加针对生成 unit 依赖关系和“一次注入后能完成 stamp、不会自重启”的回归验证。
- **Disposition**：退回 `engineer`。

### HIGH / SECURITY — B2：启用的 systemd-coredump 可把 secret 从 RAM/argv 持久化

- **位置**：`hosts/acorn/default.nix:137-168`；`hosts/axiom/default.nix:351-353`、`hosts/axiom/default.nix:580-597`
- **证据**：Acorn 与 Axiom 的有效 NixOS 配置均启用 `systemd.coredump`，相关 RustDesk units 没有可验证的 non-dumpable control。systemd-coredump 会把崩溃进程的命令行写入 journal 的 `COREDUMP_CMDLINE`，默认还可保存 core image。
- **影响**：
  - Axiom 的 `rustdesk --password ...` 若在短窗口内崩溃，永久密码可从被接受的瞬时 argv exposure 变成持久 journal 字段；provision shell 的内存也短暂持有 plaintext。
  - Acorn 的 hbbs/hbbr 长期在内存中持有 server private key；公网输入触发的 panic/crash 可能把该 key 写入持久 coredump storage。
  - stdout/FIFO 重定向、`set -x` 禁止和 root-only stamp 均不能缓解 coredump metadata/core image。
- **为什么不属于已接受边界**：RFC 接受的是 trusted endpoint 上的瞬时 argv 与持续 local IPC visibility；它仍明确禁止 secret 进入日志或持久工件。coredump persistence 未被该例外接受。
- **最小修复方向**：在读取 server key/password 之前，使相关完整进程树不可 dump，或采用经锁定 systemd/kernel 行为验证的等效 per-unit policy；不能只假定 stdout 重定向或 `LimitCORE` 在 piped coredump handler 下足够。用 synthetic marker 验证不会产生 cmdline/core evidence，绝不能用真实 secret 做测试；同时审计 Charlie 的 crash-report/core policy并记录非秘密结论。
- **Disposition**：退回 `engineer`；若只能通过全局 coredump policy 或改变 accepted argv design 解决，则回到 `spec-rfc`/`review-rfc`。

## 3. Verification blockers after code repair

这些不是把 DNS/TCC/Wayland 等 runtime gate 伪装成代码缺陷，但在配置 PR **merge 前**仍须关闭。

### MEDIUM / VERIFICATION — V1：recipient、payload 与 keypair ceremony 尚无可追踪 PASS evidence

- **位置**：`docs/rfc.md:216-225,378-382`；`docs/test-report.md:133-143,154-164`
- **已确认**：三个 `.age` 文件均为单一 SSH recipient 的合法 age envelope，ciphertext 彼此独立；`secrets.nix` recipient symbol、各 host 的 `modules.agenix.sshKey` 与 runtime owner/path 静态对齐。提交的 server public material 具有 canonical Ed25519 public shape，并由 Acorn public file及两端 client config使用同一来源。
- **尚不能由只读 review 证明**：每个 ciphertext 确实可由目标 identity 解密、两个 client payload 满足格式且不同、server private/public material 属于同一 keypair。最新 test report 明确没有执行这些检查。
- **要求**：按 RFC 在目标 identity/受限 ceremony 中只记录 pass/fail；不得输出 plaintext、ciphertext、fingerprint、digest 或值。该证据由 `verify-change` 收口。

### MEDIUM / VERIFICATION — V2：Charlie 只有 eval/generated-script evidence，没有 Darwin build/store signature evidence

- **位置**：`docs/test-report.md:102-115`；`docs/rfc.md:257-262,349-357`
- **影响**：Linux 上的 eval、XML parse、shell syntax 与 semantic harness 不能证明 ARM64 DMG 可在锁定 nix-darwin 上完成 build，也不能替代 store bundle 的 `codesign`/`spctl`。
- **要求**：在 Charlie 或可信 `aarch64-darwin` builder 完成 toplevel build及 store-bundle signature gate，作为配置 PR merge 前证据。staging/destination signature、真实 launchd 与 TCC 仍是 merge 后部署 gate。

## 4. Non-blocking observations

### MEDIUM / SECURITY HARDENING — Charlie root daemon 使用可预置的 `/tmp` 日志路径

- **位置**：`hosts/charlie/default.nix:775-778`
- Root LaunchDaemon 的固定 stdout/stderr path 位于用户可写目录。当前 single-owner local trust assumption 降低了现实攻击面，但这仍比“本地进程可见永久密码”更宽：预置文件/symlink 可能影响 root 打开的目标，且日志内容默认落入共享临时目录。
- 建议改到 activation 预建的 root-owned 目录或 `/dev/null`，并继续保证日志不含 secret。若本地进程不再全部可信，应提升为 blocker并重新审查 endpoint trust boundary。

### MEDIUM — Semantic harness 有效但边界有限

- **位置**：`test/rustdesk-charlie-safety.py:47-79,154-230,359-418,465-568`
- Harness 不只是 grep：它实际执行转换后的 transaction/provision、注入 failure/signal，并检查 timeout、FIFO、stamp 与 attempt budget；结合 test report 的额外 boundary-reach audit，当前 Charlie shell 语义证据有价值。
- 但它依赖 regex/text extraction，并 mock 掉 signing、public config 与 launchctl；提交版本没有对每次 replacement/boundary-hit 做强断言，也不覆盖真实 Darwin 或 Axiom systemd dependency semantics。因此不能用它关闭 V2，也没有发现 B1。
- 建议增加“所有转换必须命中”“转换后不得残留 production path”“故障确实到达目标 boundary”的断言。

### LOW — Reviewer-facing task docs 有少量状态陈旧

- `docs/test-report.md:16,145-152` 仍称 semantic harness 不在 scope，但当前 `plan.md:53` 与 `docs/rfc.md:460-464` 已明确纳入该精确文件；因此实际 scope **没有越界**。
- `tasks.md:5-17` 与 `log.md:34-40` 仍显示 engineer 尚未开始。它们不改变本次技术 verdict，但应在 PR 前同步，避免 reviewer 误读。

## 5. Checks that passed

- **Scope**：生产变更限于三台 host/secrets；额外文件仅为 RFC 已授权的 Charlie semantic harness 与 Legion docs。
- **Acorn key/service/firewall shape**：agenix custom target owner/mode、public symlink、双 unit key preflight/restart trigger、signal/relay 双 `-k _`、`openFirewall=false` 均符合 RFC；NixOS firewall 仅新增 TCP 21115-21117 与 UDP 21116，未新增 21114/21118/21119。
- **Axiom（除 B1/B2）**：public config 先于 root service、root/user public-field checker、root-only runtime secret/stamp、FIFO result check、revision trigger、canonical host mapping与既有 direct-route依赖均保持；未开放 client inbound firewall。
- **Charlie（除待验证项）**：fixed-output 1.4.3 app、activation-before-launchd、unknown app fail-closed、ownership marker、same-filesystem staging/backup transaction、destination signature checks、service/agent/provision plists、outer/inner hard timeout、`RunAtLoad` + `StartInterval`、三次 attempt budget、root/user post-restart public check及 marker-gated rollback均存在。
- **Secret/store/Git**：未发现 decrypted secret read、secret Nix interpolation、`set -x`、password/private-key literal进入 unit/plist/derivation/Legion docs；`.age` 受 binary attribute保护。Legion docs不包含实际 RustDesk public-key value或ciphertext payload。ciphertext与公开 server key作为各自类别可提交，但 V1 必须先给出非秘密 ceremony evidence。
- **Accepted local boundary**：文档持续、诚实地保留 RustDesk 1.4.3 password argv窗口与 world-accessible local IPC exposure；没有把 root-only age source/stamp误述为对同机进程的密码隔离。
- **Rebase risk**：分支落后 `origin/master` 1 个 commit；上游变更没有与本任务生产路径重叠，文本冲突风险低。仍须在 PR checks 前更新 baseline并复验，且生产 switch只能来自最终 merged clean commit。

## 6. Gates after configuration PR merge

以下是 merge 后部署/验收 stop conditions，不是当前代码 finding；任何一项失败都应停止后续 host rollout并按 RFC rollback：

1. 刷新到 clean、与 `origin/master` 对齐的 merged commit，三台 host记录并使用同一 commit；不得从 feature worktree switch。
2. 创建并从公共 resolver 验证 DNS-only record；确认 Charlie 不再处于 NXDOMAIN路径。
3. Acorn：目标机 secret target/symlink、`StateDirectory`/service namespace readability、keypair一致性、hbbs/hbbr health、journal、listener与host firewall全部通过；Aliyun SG仅开放TCP 21115-21117和UDP 21116，并验证21114/21118/21119关闭及费用/流量owner。
4. Axiom：实际 switch后验证 direct route、host mapping、root service/user server、provision stamp、rotation trigger、reboot恢复与 active Hyprland session；锁屏、DPMS、login screen按已知平台边界分项记录。
5. Charlie：staging/destination signature、unknown-app/marker现状、三个launchd jobs、root→user sync、真实retry/restart/stamp通过；人工授予Screen Recording、Accessibility、Input Monitoring，再测试Aqua、sleep/FileVault/login-window边界。
6. 完成双向正确密码成功、错误/旧/跨机密码失败、强制relay、回退通道与rollback验证；证据只能记录pass/fail，不能读取IPC password或保存process argv。
7. 部署证据必须继续披露永久密码的argv/local IPC accepted exposure；最后通过独立follow-up evidence PR收口，不得用配置 PR宣称生产部署完成。

## 7. Gate handoff

1. **现在**：`engineer` 修复 B1/B2；建议同时处理 Charlie `/tmp` root log hardening。
2. **然后**：`verify-change` 复验 systemd restart拓扑、non-dumpable/coredump行为、Darwin build/store signature及V1 ceremony pass/fail evidence。
3. **最后**：重新运行 `review-change`；只有 blocker归零且pre-merge verification关闭后，才可判定 **PASS for config PR**。
