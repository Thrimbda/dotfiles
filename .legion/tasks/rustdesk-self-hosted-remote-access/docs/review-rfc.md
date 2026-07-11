# Review RFC: RustDesk 自托管远程访问（简化自动部署）

> **Current final verdict**: **PASS**
> **Current review round**: 4（RustDesk Server 1.1.14 / Client 1.4.8 简化方案）
> **Engineer gate**: **允许进入 `engineer`**
> **Current sources of truth**: 最新 `../plan.md`、`rfc.md`、`research.md`
> **Supersedes**: 下文历史 review 中的 1.4.3、`--password-file`、exact-OS crash attestation、synthetic crash framework 与相关 18 项 hard requirements
> **Secret boundary**: 本轮未打开任何 `.age` plaintext，未读取未跟踪凭据，也未输出 server public-key value、ciphertext 或 secret-derived value
> **Reviewed**: 2026-07-11

## Current final decision

**PASS**。新 RFC 已把用户选择的简化风险边界、最小实现、验证和逐机回滚闭环；本轮没有发现会使设计不可实现、不可验证或不可回滚的 blocking finding。

本 PASS 只批准当前设计进入实现，不批准 worktree 中仍存在的旧 1.4.3/patch/attestation 实现，也不批准生产部署。

旧 `review-rfc` / `review-change` 对 password-file patch 和企业级 crash attestation 的要求现在只具有历史可追踪性，**不是当前 engineer gate**。仍然有效的结论只有已被新 RFC 明确保留的基础约束，例如 Axiom 的 `Wants=` + `After=`、merge-before-switch、最小防火墙、官方签名和逐机回滚。

## Findings

### Blocking findings

**无。**

### Implementation guardrails（非 design blocker）

1. RustDesk 1.4.8 的 `--password` 分支以文本区分结果：成功输出单行 `Done!`，错误也打印文本后正常返回；不能只凭进程退出码证明 password 已设置。Engineer 应采用 RFC 已允许的 root-only runtime temporary output，精确匹配成功结果后立即删除，再提交 stamp；单独丢到 `/dev/null` 不足以满足 RFC 的“成功后才写 stamp”。这不需要 source patch或持久日志。
2. 为使用户接受的 crash residual 保持为 non-core metadata 而不是传统 memory core，按 RFC Option D 保留 secret-bearing service/provision job 的低成本 per-unit `LimitCORE=0` / `Core=0`。只验证 effective limit，不做 synthetic crash、全树 artifact scan或 attestation，也不据此声称 metadata 已消失。

## Review matrix

| Lens | Verdict | Review result |
|---|---|---|
| Server/client versions | **PASS** | 当前 lock 上 `nix eval --raw .#nixosConfigurations.acorn.config.services.rustdesk-server.package.version` 为 `1.1.14`；`nix eval --raw .#nixosConfigurations.axiom.pkgs.unstable.rustdesk.version` 为 `1.4.8`。Unstable lock rev 为 `b5aa0fbd538984f6e3d201be0005b4463d8b09f8`，对应 package 定义直接 fetch tag 1.4.8，未使用 task-owned patch。 |
| Charlie artifact/hash | **PASS** | GitHub official release API 当前 asset id `453625205`、size `25889107`、digest `sha256:7f8acfb0dcab21d4c8fe570902be70a02ed0db007daa5ebfe1e0119487a5fc17`；`nix store prefetch-file` 实取结果为 `sha256-f4rPsNyrIdTI/lcJAr5woC7Q2wB9ql6/4eARlIel/Bc=`，与 RFC 完全一致。Hash pin 会使上游资产漂移 fail closed。 |
| Normal-path secret boundary | **PASS** | Secret source 是逐机 root-only agenix runtime file；生成的 Nix/script/unit/plist 只包含 runtime path，不包含 plaintext。Helper 禁止 trace/export/log plaintext，stdout/stderr 不进入常规日志，临时结果只用于匹配 `Done!` 并立即删除。短生命周期变量及 bounded `rustdesk --password "$password"` argv 是明确接受的明文窗口。 |
| Accepted residual | **PASS** | RFC 明确披露 trusted single-owner endpoint 上的短暂 argv 可见性，以及恰在该窗口崩溃时 non-core crash metadata 持久化的低概率残余；没有把 `LimitCORE=0`/`Core=0`、agenix 或 1.4.8 IPC hardening写成 attestation，也不再要求全局 handler、真实-secret crash injection 或 synthetic crash suite。 |
| Axiom dependency/replay | **PASS** | Provision 对 main service 只允许 `Wants=` + `After=`，同时禁止 `Requires=`、`PartOf=`、`BindsTo=` 和反向依赖，故 helper 内 restart main 不会传播成 self-restart。Readiness 失败不读 password；每次执行最多一次 bounded invocation；无自动无限 restart，失败后由 operator 显式重试。 |
| Charlie retry/replay | **PASS** | `RunAtLoad` + `StartInterval=300` 只自动重试 readiness；同一 composite revision 在 argv 窗口前持久化一次 attempt reservation，password invocation 失败后 interval 不再重放，必须 operator reset 或 revision 变化。Success stamp 使后续调度 fast-skip。 |
| Server key/firewall | **PASS** | RustDesk key 与 SSH key 分离；private key 只经 agenix 到 `/var/lib/rustdesk/id_ed25519`，hbbs/hbbr 都用 `-k _` 且有 service-identity fail-closed preflight。`openFirewall=false`，只声明 TCP 21115-21117 与 UDP 21116；21114/21118/21119 不开放。 |
| macOS signature/TCC | **PASS** | Charlie 使用 hash-pinned official ARM64 DMG，不 fixup/strip/改 Info.plist、不 ad-hoc re-sign；store 与 destination 都必须 `codesign --verify --deep --strict` 和 `spctl` 通过，未知 app 不静默覆盖。TCC 三项保持人工 gate，没有能力夸大。 |
| Wayland/platform limits | **PASS** | Axiom active Hyprland/Wayland、Charlie Aqua/LoginWindow/TCC 由真机矩阵界定；lock/login/sleep/FileVault 结果分项记录。它们是部署/验收 stop conditions，不是尚未裁决的设计问题。 |
| Merge/rollback | **PASS** | 配置 PR 必须先 merge，三台只从同一 clean `origin/master` baseline switch；Acorn SG/DNS、Axiom mutable config/password、Charlie jobs/app/TCC 都有独立 containment 和 rollback 路径，SSH/reverse SSH/ToDesk 始终保留。 |
| Simplification/scope | **PASS** | 当前旧实现 diff 为 `+3729` 行。RFC 明确删除 435 行 patch 与 570/918 行两个 harness（仅三项即移除 1923 行），拒绝 Charlie crash probe/attestation 和跨平台 framework，并把生产边界收回六组 host/secret 文件；因此最终实现应明显缩小，而不是把旧强化体系换名保留。 |

## Non-design deployment gates

以下项目会阻止相应 rollout 阶段，但不阻止进入 `engineer`：

1. Acorn/Axiom eval/build，以及 Charlie 真正的 aarch64-darwin build、store/destination signature。
2. 配置 PR merge 后刷新到 clean merged baseline，并记录三台共同使用的 commit。
3. 公共 DNS-only A record、Aliyun SG 最小规则、21114/21118/21119 外部负测与 relay 费用 owner。
4. Charlie TCC/Aqua/LoginWindow 与 Axiom active Hyprland/Wayland 真机矩阵。
5. 两台逐机 password 正测、旧/错误/跨机 password 负测，以及 direct/forced-relay/回退路径。

## Engineer handoff

**允许 `engineer`：是。** Engineer 应只实现当前 1.1.14/1.4.8 host-local RFC，并删除旧 patch、两个 Python harness及嵌入 host 配置的 crash-attestation/probe framework。不得把下文历史 18 项 hard requirements 重新带回实现。

若实现需要重新引入 source patch、全局 crash policy、第二套永久 server 地址、额外公网端口、共享 RustDesk framework，或改变 merge-before-switch / rollback 边界，才需要停止并重新进入 `spec-rfc` / `review-rfc`。

---

## Historical archive — superseded, not the current gate

> **Status of everything below**: 历史原文，仅用于追踪旧设计如何演进。其 `Final verdict`、`Engineer hard requirements` 和 gate handoff 均已被上面的 Round 4 current final verdict 取代。
> **Still carried forward**: `Wants=` + `After=` 防 self-restart、merge-before-switch、key/firewall/signature/TCC/rollback 基础约束。
> **Explicitly superseded**: RustDesk 1.4.3、Linux `--password-file` patch、no-secret argv 绝对目标、exact-OS crash attestation、synthetic crash markers/full artifact scan，以及由此产生的 enterprise-style test framework。

<details>
<summary>展开 Round 1-3 历史 review 原文</summary>

# [Historical] Review RFC: RustDesk 自托管远程访问

> **Final verdict**: **PASS**
> **Review round**: 3（`review-change` B1/B2 设计修订复审；前两轮历史保留在下文）
> **Engineer gate**: **允许进入 `engineer`，但必须满足 Round 3 的硬要求**
> **Reviewed**: 最新 `docs/rfc.md`、`docs/research.md`、`docs/review-change.md` 的 B1/B2，以及锁定的 systemd 258.7 / RustDesk 1.4.3 source evidence；前两轮 review 记录作为历史输入
> **Secret boundary**: 本轮未打开任何 `.age` plaintext，未读取主工作区未跟踪 `acorn_password`，未生成 secrets
> **Date**: 2026-07-11

## Final decision

**PASS**。首轮 B1/B2 均已进入 contract 并在 RFC、research、phase order 与 milestones 中闭环；未发现会使当前设计不可实现、不可验证或不可回滚的剩余 design blocker。

## First-review traceability

| Finding | 首轮问题 | 当前修订与复核证据 | 状态 |
|---|---|---|---|
| B1 — local IPC / trust boundary | RFC 一度把本地低权限主体视为 adversary，但 RustDesk 1.4.3 的 `0777` IPC 可返回 permanent password，控制不可实现 | `plan.md:27` 已把 axiom/charlie 定义为 single-owner trusted endpoints；`rfc.md:12,60,170,179,188-208,424` 明确 agenix 只保护 source/rollout，不声称对同机进程保密，并规定 trust boundary 改变时停用、轮换和重新 RFC | **Resolved** |
| B2 — merge-before-switch | 原阶段顺序允许从未 merge feature worktree 做 production switch，repository truth、rollback generation 与 PR 终态可能分叉 | `plan.md:17-19,33,45,66-71`、`tasks.md:17-31`、`rfc.md:16,64,235,257-300,402-418,425` 已固定“配置 PR merge/refresh → clean merged commit production switch → follow-up evidence PR” | **Resolved** |

首轮发现保留为历史证据，不再作为当前 blocker。旧的 FAIL gate 由本文件本轮 final verdict 取代。

## Re-review checks

### 1. Trusted endpoint boundary — PASS

- contract 明确所有本地交互账号及其进程位于永久密码可信边界内。
- RFC 持续披露 argv window 与 world-accessible local IPC，不再把 root-only age source/stamp 误写成运行时本机隔离。
- endpoint 变为 multi-owner、出现不可信本地进程或要求本地账号隔离时，有明确失效条件：停止使用、轮换并重新 RFC/review。

### 2. Repository and deployment lifecycle — PASS

- 配置与安全评审、required checks、PR merge 和 baseline refresh 明确先于任一 production switch。
- acorn、axiom、charlie 必须使用同一 clean merged commit；feature worktree deployment 被明确禁止。
- runtime evidence 在部署后通过独立 follow-up evidence worktree/PR 收口；milestones M1/M2/M3 与 `plan.md`/`tasks.md` 一致。

### 3. Design gate vs execution gates — PASS

- RFC Phase 0 只保留 review/design drift 作为 design stop conditions。
- DNS、Aliyun SG、macOS TCC、Wayland/portal 与真机签名/同步结果被明确归入对应 static/deployment/acceptance phase，不再伪装成未决设计问题。
- 每项 execution gate 都有 stop/rollback boundary；未通过不得推进下一主机，也不得扩大能力声明。

### 4. Previously accepted technical design — intact

- **Server key**：Server 1.1.14 working-directory `id_ed25519`、`-k _` 语义、hbbs/hbbr 同 public value、缺 key fail-closed 均保留。
- **agenix/systemd**：custom target parent、`DynamicUser`/`StateDirectory` 迁移、`PrivateMounts` namespace read check、两个 unit 共同 restart triggers 均保留。
- **NixOS firewall**：`openFirewall=false`、acorn `mkForce` TCP list 显式加入 21115-21117、UDP 只加 21116、21114/21118/21119 双层拒绝均保留。
- **Linux bootstrap**：pre-service public config、post-service password/main IPC、root/user restart、bounded retry、`RemainAfterExit`/revision triggers、local stamp 与跨端认证分离均保留。
- **macOS**：hash-pinned DMG、store/staging/destination 三段签名门禁、unknown existing app fail-closed、ownership marker、backup restore、raw launchd plist 与 generation/job rollback 均保留。
- **Secret ceremony**：不使用会把 server private key 放入 argv 的 `validatekeypair`；file-based public derivation compare、最小 recipients、target decrypt-to-`/dev/null` 与无秘密证据规则均保留。
- **Verification/rollback**：不输出整份 client config、password、private key、argv 或 digest；正/负跨端认证、逐机 rollback、mutable state cleanup 与 SSH/ToDesk 回退均保留。

## Remaining non-design gates

这些项目不阻塞进入 `engineer`，但会阻止进入或推进相应 execution phase：

1. 完成三台配置的 eval/build/security review，charlie store bundle 通过 `codesign`/`spctl`。
2. 配置 PR merge，清理/刷新到与 `origin/master` 对齐的 clean merged commit，并记录 commit ID。
3. 创建并公共验证 `rustdesk.0xc1.wang` DNS-only A record。
4. 明确 Aliyun SG owner、最小 TCP/UDP ingress 与费用/流量告警责任，并验证 21114/21118/21119 未开放。
5. charlie staging/destination 验签、raw launchd load、root/user sync、password/restart/stamp 真机验证；人工授予三项 TCC。
6. axiom password rotation trigger 与 Hyprland active-session 必测；锁屏、DPMS、login screen 分项记录。
7. 三台实际 switch、双向正/负认证、relay/回退验证完成后，follow-up evidence PR 到 terminal state。

acorn exact switch command 已确认，不属于 remaining gate；sudo password 仍只能由 operator 交互提供，agent 不得读取 `acorn_password`。

## Gate decision

**允许进入 `engineer`**。实现必须保持当前 contract/RFC 边界；若需要改变 trusted endpoint、端口集合、永久密码模式、macOS ownership/signature 方案或 merge-before-switch 顺序，必须停止并重新进入 RFC/review。

---

## Round 3 — `review-change` B1/B2 设计修订复审（当前结论）

### Decision

**PASS**。本轮没有发现会使修订后设计不可实现、不可验证或不可回滚的 blocker。Axiom 的 file-based secret input 与局部 core policy 比全局 `core_pattern` 方案边界更小；B1 的依赖拓扑消除了已确认的自重启传播；Charlie 方案没有把 `Core=0` 误述为 `ReportCrash` 保证，而是把剩余风险收敛成 exact-OS、fail-closed 的部署前 gate。

本 PASS 只批准 RFC 中的设计，不批准当前生产实现或部署。上文 Round 1/2 内容继续作为历史记录；本节是当前 engineer gate。

### Findings

#### 1. Axiom root-only `--password-file` — PASS

- 锁定的 1.4.3 call site 足够局部：现有 root/installed 分支最终只把一个 `String` 交给 `ipc::set_permanent_password`。在该分支增加 Linux-only file reader，不需要改变 IPC、配置格式、网络协议或 signed macOS bundle。
- RFC 要求先 open，后在同一 opened fd 上 `fstat`、有界读取和解析。这消除了 pathname 的 check-then-open TOCTOU；agenix symlink 在 open 后切换时，调用读取稳定的旧 inode，或严格失败，不会改读随后替换的 pathname。root 对已打开 inode 的主动并发修改属于 trusted-root boundary，不值得为此引入锁或全局 helper。
- regular file、uid 0、无 group/other 权限、32–64 ASCII base64url bytes、无换行和 65-byte hard bound 形成了可测试的输入合同。成功仅输出 `Done!`、失败只输出 generic category，可避免 path/content/digest 进入 journal。
- exact 1.4.3 assertion、patch revision、保留原 nixpkgs patches、升级时重审 call site/parser/core behavior，以及 build 失败时停用或留在最后 safe generation，使 patch 可维护且可回滚。

#### 2. Linux `LimitCORE=0` + no-secret argv/environment — PASS with bounded claim

- 锁定 systemd 258.7 在 `RLIMIT_CORE < page_size` 时不保存或解析 core image，但仍写入 `COREDUMP_CMDLINE`、`COREDUMP_ENVIRON`、open-fd/path、limits 等 metadata。因此两项控制缺一不可：secret value 不进入 argv/environment 用于消除 metadata secret source，soft+hard core limit 0 用于消除 memory image。
- Acorn 两个 daemon tree、Axiom config/main/provision tree，以及 package wrapper 覆盖的 manual GUI entry 已纳入边界。root trees 再从 capability bounding set 排除 `CAP_SYS_RESOURCE`，可阻止跨 exec/uid/sudo 后重新抬高 hard limit；实际 descendants 的 `/proc` 证据仍是必须的，不能只看 unit 文本。
- 结论只保证不持久化 password/private-key value 或 memory image，不保证没有非秘密 coredump event。RFC 已准确保留该边界。

#### 3. Axiom `Wants=` + `After=` topology — PASS

- 锁定 `systemd.unit(5)` 明确：`Requires=` 会在被依赖 unit 被显式 stop/restart 时传播 stop/restart；`Wants=` 只在启动 transaction 中弱拉起目标，`After=` 只排序。删除 `Requires=`、`BindsTo=`、`PartOf=` 及其他 stop/restart propagation 后，provision 内执行 `systemctl restart rustdesk.service` 不会为仍在运行的 provision 自动排入 stop/restart job。
- main service/IPC/public readiness 改由脚本显式检查，故弱依赖不会把 main failure 误判为成功。保持 provision PID、完成 post-restart check 后才原子提交 stamp，是可执行、可回归验证的闭环。

#### 4. Charlie official DMG / crash-artifact gate — PASS with empirical boundary

- 保持 hash-pinned、官方签名 DMG，不 patch binary/Info.plist，避免破坏签名与 TCC identity。service、server、provision 三个 jobs 各自设置 soft+hard `Core=0`，可覆盖 provision shell/timeout/CLI descendants 的传统 Mach core；RFC 没有把它外推为 Apple `ReportCrash` 控制。
- 在 root LaunchDaemon、Aqua、LoginWindow 与 LaunchServices/manual-GUI context 使用 synthetic argv + memory marker，要求 reporter 确实处理 crash，再扫描完整 report/log/core artifacts；无 report、不可读、不可关联或 marker 命中均 FAIL。这是 signed-bundle 约束下可实现的 OS-build-scoped evidence，不是永久平台保证。
- attestation 缺失、probe revision 不同或 `sw_vers -buildVersion` 漂移时，三个 managed jobs 均在 exec RustDesk 前 fail closed；provision 在 gate PASS 前不得打开真实 password 或构造 upstream `--password` argv。OS/app 变化前停 jobs、变化后重新 gate，形成可验证的 re-block boundary。
- manual LaunchServices entry 不能继承三个 job 的 limit，也不能由 launchd guard 技术性拦截。RFC 以 single-owner trusted endpoint、当前-build manual context probe、无 attestation 时禁止手工启动来收口；这是明确接受的 operational residual，不得改写成强制系统隔离。

#### 5. Rollback and blast radius — PASS

- Linux 只改 package-local input 和相关 unit/process trees，不替换全局 `core_pattern`，不会牺牲其他服务的 crash diagnostics。Charlie 也不全局卸载 `ReportCrash`。
- rollback 固定先停/禁用 provision 与全部 RustDesk processes，再撤销 mutable state/app/jobs；任何缺少 file-input/core/attestation invariant 的旧 generation 都不得在 RustDesk 运行时恢复。安全目标是最后 safe generation 或停用 RustDesk，而不是恢复旧 secret argv automation。

### Engineer hard requirements

以下均为本次 PASS 的规范性条件；任一缺失都应在 `verify-change` / `review-change` 判 FAIL，不能以实现细节豁免：

1. **Patch scope/version**：patch 只能触及 locked RustDesk 1.4.3 的 Linux root/installed password-file branch及紧邻测试；保留 nixpkgs 原 patches。package version、upstream source、patch content/revision必须共同进入可审计 identity 与 provision invalidation；任何 RustDesk/nixpkgs 升级都必须重审 call site并重跑全部安全测试。
2. **Single-fd file safety**：只 open 一次并使用 close-on-exec fd；type/uid/mode/length检查与读取必须全部针对该 fd，禁止 `stat(path)` 后重新 `open(path)`。允许 agenix 的 root-controlled symlink，但校验最终 referent；runtime path及parent必须处于预期的root-controlled、non-writable boundary。
3. **Exact parser contract**：按 bytes 校验 `[A-Za-z0-9_-]{32,64}`；禁止 trim，拒绝 padding、空白、换行、NUL、非 ASCII、短/长输入。最多读取 65 bytes并确认 EOF，使 fstat 后增长也 fail closed；实际读取长度必须再次落在 32–64。
4. **Output/error contract**：只有 IPC 成功可在 stdout产生一次且仅一次 `Done!`。所有 open/metadata/read/format/IPC failure只返回固定 generic category；stdout/stderr/journal不得出现path、content、digest、Rust `Debug` value或secret-derived特征。失败不得调用 password IPC，成功只调用一次。
5. **Patch tests**：至少覆盖 non-root、non-regular、wrong uid、group/other bits、31/32/64/65 bytes、newline/NUL/non-ASCII/padding、short read/growth、symlink rotation及 success/failure output。TOCTOU 测试必须证明 open 后 pathname替换不会切换读取对象。只使用 synthetic marker。
6. **No-secret Linux command surface**：所有 generated unit/script/wrapper、process argv、environment与journal command metadata只能出现公开配置或 runtime path；Axiom 受管路径不得再出现 `--password <value>`，shell不得把 plaintext读入变量。digest helper也必须位于 core-zero tree且不得输出 digest。
7. **Complete Linux tree**：Acorn signal/relay 和 Axiom config/main/provision units必须生成并实测 soft/hard `LimitCORE=0`；所有 root trees的 effective capability bounding set必须没有 `CAP_SYS_RESOURCE`，package/internal binary不得带可恢复该 capability 的 file capability。公开 wrapper必须先把 soft/hard core都降为0再 `exec`，desktop entry只能走该 wrapper。
8. **Descendant evidence**：实测 `rustdesk --service -> sudo -> user --server -> tray/children`、provision shell/checker/digest/patched CLI，以及 Acorn daemon descendants 的 effective limits/capabilities。任一 descendant 非0或可重抬hard limit即 FAIL；不能以 parent unit配置代替。
9. **Linux crash regression**：先用 unsafe synthetic argv positive control证明 scanner可命中 `COREDUMP_CMDLINE`；safe cases从file把marker读入memory后crash。逐 case确认 coredump event实际发生、`COREDUMP_RLIMIT=0`、无 `COREDUMP_FILENAME`/embedded `COREDUMP`/external image，且完整 journal包括应用 stdout/stderr均无 marker。scanner不得把 marker 放入自己的 argv。
10. **B1 generated/runtime dependency**：provision 对 main service只能有 `Wants=` + `After=`。同时检查正反向 runtime properties，禁止 `Requires`/`Requisite`/`BindsTo`/`PartOf`/`PropagatesStopTo`/`StopPropagatedFrom` 或等效 restart propagation。回归必须证明 main restart 前后 provision PID不变、file-input调用恰好一次、post-check完成后才写原子 stamp；main/IPC failure时零调用、零 stamp。
11. **Charlie signed boundary/core limits**：不得修改或 ad-hoc re-sign official bundle。store/staging/destination三段签名检查必须保留。三个 raw plists均设置soft+hard `Core=0`，并在真实 root daemon、每个 agent context及 provision descendants读取effective limits；仅检查plist XML不够。
12. **Versioned attestation**：attestation至少绑定 exact OS build、RustDesk app version/source hash、probe source revision、全部required contexts和总 PASS；只能在全部 case完成后原子发布到root-owned、regular、non-writable location。不得把marker、report正文或secret写入attestation。app/hash、OS build或probe revision任一变化都使旧attestation无效。
13. **Guard-before-secret ordering**：service/server/provision三个managed jobs都先验证attestation再exec。provision还要在真正 open/read age target及构造 `--password` argv的紧邻位置重新验证，不能只在可能等待数分钟的job入口验证。missing/mismatch/unreadable/indeterminate一律不读secret、不启动RustDesk、不写success stamp。
14. **Credible Charlie probe**：每个 context都必须生成可按PID/time关联的新 `.ips`/legacy event，不能以没有artifact判PASS。argv marker与memory-only marker分开；memory marker须放在crashing thread的live stack/register-reachable state，而不是仅放在不一定被reporter采样的闲置heap；scanner先用marker-bearing fixture做positive control。
15. **Complete Charlie artifact inventory**：扫描system/user DiagnosticReports、legacy locations、完整 `.ips`、unified log、job stdout/stderr、RustDesk自有日志及 `/cores`；同时盘点当前host启用的持久exec/crash telemetry，包括启用时的OpenBSM `/var/audit` 或同类agent。任何channel不可读、范围不可判定、reporter未完成、marker命中或产生对应core image都阻塞真实provision。
16. **OS-drift re-block**：初次gate必须发生在任何RustDesk/provision process读取真实password之前。OS更新前先停全部RustDesk jobs/processes；更新/重启后旧attestation必须让managed jobs fail closed，重新PASS前不得手工从LaunchServices启动app。若无法保证该operational boundary，停止并退回 `spec-rfc`。
17. **Rollback**：rollback前先disable/stop provision并停止完整RustDesk tree；必要时用runtime mask确保unsafe旧unit不会在switch中短暂启动。只能回到不含RustDesk或同样满足file-input/core/attestation invariant的generation。Charlie旧generation缺任一gate时保持jobs stopped，并按ownership marker恢复/删除app；SSH/reverse SSH/ToDesk必须一直可达。
18. **Evidence hygiene**：所有验证只记录case、版本/build/revision和PASS/FAIL；不得保存真实argv、password、private key、digest、synthetic marker或crash正文。真实secret不得用于任何crash test。

### Gate handoff

**允许 `engineer`：是。** Engineer 只能按上述硬要求实现 B1/B2；随后必须进入 `verify-change`，再由新的 `review-change` 判断实现与配置 PR readiness。若 Charlie exact-OS probe无法给出确定 PASS、Axiom patch需要扩大到 IPC/配置协议、或必须改用全局 coredump/ReportCrash policy，立即停止并退回 `spec-rfc` / `review-rfc`。


</details>
