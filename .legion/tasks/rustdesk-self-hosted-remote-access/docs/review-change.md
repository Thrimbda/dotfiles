# Review Change: RustDesk rollout

## Current authoritative review — final deployed force-relay and Charlie v10 candidate

### Findings

#### Blocking findings

无。

#### Non-blocking findings

1. **MEDIUM — task-owned server source patch需要持续升级门禁。** 当前patch由1.1.14 version assertion、fixed source、zero-fuzz apply、exact source differential、fresh package tests和真实same-intranet relay共同约束。未来更新server source/version时，必须重新证明patch仍必要、只应用一次、`ALWAYS_USE_RELAY=false`保持旧行为，并重跑same-intranet runtime。
2. **MEDIUM — 全量relay集中availability、DoS、带宽和费用风险。** Runtime已证明目标会话进入Acorn hbbr并恢复画面/输入，但没有长期soak、容量或账单周期数据。用户已接受为non-blocking residual。
3. **LOW — production先于commit/PR/merge从dirty candidate激活。** Acorn live package、Charlie v10 revision和当前production diff已关联到同一candidate；merge用于关闭Git source-of-truth差距，不能把现状描述成clean-merged deployment。
4. **LOW — 本轮只明确记录correct-password与wrong-password。** 未单列old/cross-host fresh negative；Input Monitoring未开启但键盘实测通过。不得扩大为这些未执行case已经PASS。

### Verdict

**PASS — 当前candidate没有blocking correctness、security、scope或verification-evidence finding；可以提交exact diff、创建PR，并在required checks通过且diff未漂移后merge。** RFC lag按用户明确决定不是blocker，不重开RFC。本结论不把长期relay运营风险声明为关闭。

> **Review target**: HEAD / `origin/master` `d85c80f3be5cfea3c857f10c26cfa72a4fa6e289` 加当前production/evidence diff
> **Direct author**: `engineer-jolly-gecko`
> **Static/build verifier**: `verify-change-fizzy-capybara`
> **Runtime verifier**: `verify-change-fizzy-yak`
> **Reviewer**: `review-change-playful-otter`
> **Security lens**: applied — protocol routing、authentication、root-to-GUI launchd context、one-attempt/finalizer state和secret boundary
> **Reviewed**: 2026-07-15

### Review conclusions

1. **Force-relay correctness — PASS。** `ALWAYS_USE_RELAY=true`时，既有代码先设置`SYMMETRIC`，新增guard再强制`same_intranet=false`，跳过`FetchLocalAddr`并进入原有`PunchHole`路径。稳定`false`时，新表达式`!force && old`逐项等于旧表达式。
2. **Package与安全回归 — PASS。** Override保留既有patch列表并追加task patch；1.1.14 assertion保持。Key preflight、`-k _`、relay host、service identity、restart policy、firewall和端口未漂移。Runtime中hbbs/hbbr均恢复并由patched package运行。
3. **`launchctl asuser` — PASS。** `asuser`切换launchd namespace而不是认证身份；root provision只重启固定GUI-domain LaunchAgent。随后validator仍要求UID c1、exact executable/arguments、PID/socket ownership和稳定identity。v9 root-context kickstart实际fail closed，v10 asuser路径实际成功。
4. **v10 state语义 — PASS。** v8→v10只改变composite digest，合法prefix仍为`charlie-rustdesk-provision-v4:`。v9 consumed attempt没有被resume；首个v10 run在发布current reservation和读取secret之前失败，因此同revision retry合法。成功后正负认证、finalizer及fast-skip均通过。
5. **Live/repo一致性 — PASS with provenance caveat。** Acorn live package、hbbr pairing、Charlie v10 revision、current stamp及fast-skip均对应当前production inputs，临时hosts/route已清理。由于部署来自dirty candidate，只能声称语义与待提交diff一致，不能声称live generation来自未来merge commit。
6. **Verification充分性 — PASS。** 证据覆盖exact patch、false-path truth table、fresh build/tests、generated units、Axiom-built Acorn activation、same-intranet relay、Charlie asuser、画面/输入、correct/wrong authentication、manual finalizer和fast-skip。Acorn没有执行Nix build。

### Commit / PR / merge readiness

- **Commit**：ready；一次性stage全部intended paths。
- **PR**：刷新`pr-body.md`和`report-walkthrough.md`后ready。
- **Merge**：required checks PASS且PR diff与本review一致后ready；无需重开RFC。
- **Deploy**：不需要再次deploy，禁止在Acorn运行Nix。

### 会话注意力摘要

- **阶段结论**：`PASS`
- **Attention state**：`none` for commit/PR/merge；长期relay费用/单点与source patch升级责任为non-blocking residual。
- **已关闭**：pre-runtime gate、authoritative review落盘、same-intranet relay、v10 auth/finalizer/fast-skip。
- **自动下一步**：刷新reviewer artifacts，提交exact candidate，完成required checks并squash merge。

---

## Historical review — Acorn force-relay same-intranet source patch (pre-runtime)

### Findings

#### Blocking findings

无。

#### Non-blocking findings

1. **MEDIUM — task-owned source patch带来明确的升级/rebase维护责任。** 当前patch只在RustDesk Server 1.1.14的`handle_punch_hole_request`中给`same_intranet`增加一个guard；version assertion、fixed source、zero-fuzz apply、patched-tree exact differential和fresh package build使当前版本的风险有界。但它依赖上游内部control-flow，不是稳定API，也没有checked-in regression test。任何server source/version升级都必须把“patch仍必要”作为显式问题，重新审查call site、zero-fuzz应用、`false`等价性、client relay选择和same-intranet runtime；不得只因patch还能带fuzz应用就继续。
2. **MEDIUM — shared package使hbbs与hbbr都进入restart blast radius。** 源码只改hbbs使用的`rendezvous_server.rs`，但`services.rustdesk-server.package`同时供`rustdesk-signal`与`rustdesk-relay`使用。Candidate generated units的两个`ExecStart`都换到新store package path，且两个unit均是changed-service restart语义；部署必须按hbbs、hbbr都会重启规划。既有registration和relay session可能中断，不能沿用上一轮“hbbr PID应保持”的结论。
3. **MEDIUM — 全量relay扩大DoS、费用与单点故障影响。** 该风险是用户要求“所有流量经Acorn”的直接代价，不是实现偏差：合法session的数据面和metadata集中到唯一Acorn/hbbr，公网21117、Acorn带宽/CPU、云egress费用和单机可用性成为持续依赖。1.1.14默认`SINGLE_BANDWIDTH=16 Mb/s`、`TOTAL_BANDWIDTH=1024 Mb/s`只是吞吐限制，不是连接数、费用预算或failover。现有key gate与最小端口降低滥用面但不消除扫描、资源耗尽或账单风险；PR前可保留该accepted architecture，deployment前仍需owner、阈值和containment动作。
4. **LOW — relay flag是可变atomic，且当前request读取两次。** Stable `true`/`false`下本patch语义正确；但上游loopback command可在进程内改变`ALWAYS_USE_RELAY`，line 713的`SYMMETRIC`决定与新增guard各自load一次。只有在本地显式切换恰好与request并发时才可能得到不同snapshot；该本地控制面与trusted-Acorn边界不是本patch新增，能切换它的actor本来就可关闭force-relay，因此不阻塞当前PR。维护建议是在未来port patch时对每个request只load一次并复用；运行时则不得把一次启动检查外推成tamper-proof保证。

### Verdict

**PASS — static/source/build证据足以创建Acorn same-intranet force-relay PR并运行required checks；不是merge、deployment、runtime relay、capacity/费用或availability PASS。** 未发现blocking correctness、security、scope、regression或verification-evidence finding。用户批准的no-RFC bypass已明确处置，不是blocker；本review不修改RFC，也不把旧Axiom-only implementation boundary伪装成当前设计。

> **Review target**: `origin/master` / HEAD `d85c80f3be5cfea3c857f10c26cfa72a4fa6e289` 加未提交的`hosts/acorn/default.nix` package override、`hosts/acorn/patches/rustdesk-server-force-relay-intranet.patch`与verifier-owned `docs/test-report.md` authoritative section
> **Direct author**: `engineer-jolly-gecko`
> **Verifier**: `verify-change-fizzy-capybara`
> **Reviewer**: `review-change-quick-fox`
> **Provenance**: author、verifier、reviewer为不同派生事件；本review独立检查candidate、pinned server/client control-flow与交付证据
> **Verification gate**: current `docs/test-report.md`对scope、exact patch application、true/false source semantics、fresh package tests、generated units与完整Acorn toplevel build为PASS；candidate runtime/deployment NOT RUN
> **Security lens**: applied — routing/protocol boundary、relay selection、key/auth continuity、ports、secret boundary、local flag mutability、DoS/费用集中与dual-service lifecycle
> **RFC disposition**: 用户明确批准“所有流量经Acorn”与no-RFC bypass；该流程滞后不阻塞本PR，本review不改`docs/rfc.md`
> **Reviewed**: 2026-07-15

### Review results

1. **Scope、minimality与no-RFC disposition — PASS。** 写入本section前，production candidate只有`hosts/acorn/default.nix`的`+5/-0` package override与13行patch文件；另一tracked delta是verifier-owned test report。没有Axiom、Charlie、module、其他package、`.age`、key material、port或RFC变更。Acorn与task docs均在`plan.md:51-58`授权范围内。旧RFC的Axiom-only implementation boundary确实滞后，但用户已显式授权本次exact exception并禁止重开RFC，故只记录provenance，不作为设计回退点。
2. **`ALWAYS_USE_RELAY=true`跳过same-intranet — PASS。** Upstream先在同一request上命中既有`ALWAYS_USE_RELAY || LAN-XOR`分支，把`ph.nat_type`设为`NatType::SYMMETRIC`。新增guard随后令`same_intranet=false`，因此不再生成`FetchLocalAddr`，而是进入原有`else`并发送包含同一`relay_server`和`SYMMETRIC` nat type的`PunchHole`。这直接覆盖用户提供的runtime residual：官方1.1.14/1.1.15在same-intranet曾停留于`FetchLocalAddr`、direct失败且hbbr无request。
3. **`ALWAYS_USE_RELAY=false`行为保持 — PASS with bounded concurrency note。** 旧表达式是`old = !ws && intranet_predicate`，candidate是`new = !force && old`；当本次判断观察到stable `false`时，`new == old`，原有WebSocket、LAN和same-public-IP判断逐项不变。Verifier的8-case truth table、exact one-block replacement与source-tree唯一文件差异共同覆盖该claim。上面的LOW finding只限制并发切换时的跨两次atomic-load表述，不否定stable false regression结果。
4. **确实进入既有`PunchHole + SYMMETRIC` relay路径 — PASS，runtime仍需闭环。** Reviewer独立检查pinned RustDesk client 1.4.9：controlled端收到`PunchHole`后，`ph.nat_type == SYMMETRIC`会直接调用既有`create_relay`，向hbbs返回`RelayResponse`并连接relay；controller收到`RelayResponse`后直接建立relay connection，最终两端在hbbr按UUID配对。该patch没有新建协议、relay实现或认证旁路，只把same-intranet分支重新导向已经存在且上一轮常规拓扑使用的路径。Static control-flow足以支持PR，但只有fresh runtime的hbbr paired/bytes positive proof与endpoint direct negative proof能证明实际data plane。
5. **Package override与升级fail-closed属性 — PASS with maintenance residual。** `(oldAttrs.patches or [ ]) ++ [ taskPatch ]`保留nixpkgs既有patch顺序并把task patch追加在后；Acorn assertion仍要求package version恰为1.1.14。当前fixed source上patch以`--fuzz=0`应用，patched source除目标Rust文件外无差异，package/checkPhase/version tests与完整toplevel均通过。版本assertion和patch/build failure会阻止无意漂移，但维护者主动更新assertion时仍必须执行finding 1的语义门禁。
6. **Key、auth、port、secret与hardening regression — PASS。** Source diff没有触及licence/key check、relay pairing、secure connection或password逻辑；Nix diff没有触及age secret、public key、`-k _`、relay hostname、firewall或service identity。Exact generated-unit differential显示两unit除shared package path外无文本变化：hbbs仍有`ALWAYS_USE_RELAY=Y`和`--relay-servers rustdesk.0xc1.wang -k _`，hbbr仍是`-k _`；三项key preflight、`LimitCORE=0`、restart policy和`rustdesk:rustdesk`身份保持。`openFirewall=false`，RustDesk exposure仍只有TCP 21115-21117与UDP 21116。本review未读取任何secret/key/config payload。
7. **Dual restart与session continuity — PASS as an explicit deployment risk。** Candidate hbbs/hbbr generated units都只因shared executable store path而变化；这证明没有旁路配置漂移，也意味着switch transaction不能假设hbbr continuity。Pre-switch已有relay session必须视为会断开，部署控制通道必须是SSH/reverse-SSH/ToDesk而不是被测RustDesk。Post-switch须分别证明两个新process identity、active状态、listener恢复和client re-registration；任一失败都阻止runtime PASS。
8. **Verification sufficiency — PASS for PR entry。** Evidence组合包含clean-baseline topology、完整production diff、whitespace、exact patch bytes和zero-fuzz apply、patched-tree recursive differential、stable true/false truth table、fresh package rebuild/checks、binary version、candidate/base generated-unit exact differential、closure linkage及完整Acorn toplevel build。Reviewer另行复核了patch上下文、server branch、pinned 1.4.9两端relay选择、generated units和baseline topology。它们足以审查一个小而明确的private patch；它们没有启动服务、执行switch、产生same-intranet session、观察hbbr request/bytes、排除endpoint direct data socket或测量capacity/cost，因此runtime gates不能降级。

### Security assessment

Security lens未发现新增credential、secret、permission、ingress或authentication bypass。Patch位于通过licence/key检查后的routing choice，只改变`FetchLocalAddr`与`PunchHole`的选择；现有secure peer authentication与hbbr `-k _`路径保持。Package rebuild会改变两个daemon executable/store identity，但generated service user、private key preflight、public key、args与端口不变。

风险变化主要在availability和concentration，而不是credential confidentiality：更多合法数据与connection metadata经过Acorn，hbbr/Acorn compromise、DoS、资源饱和和billing abuse的影响扩大；唯一relay也成为单点。Loopback `aur` command可修改global flag是上游已有local control surface，没有被远程暴露；在现有trusted-Acorn模型内不构成新增exploit，但它意味着“所有流量relay”是受控运行配置与持续观测目标，不是不可变安全属性。

### Required clean-merge runtime gates

1. 创建PR、完成required checks、明确处置本section的`attention:review`，再merge；Acorn只能从clean merged `origin/master`部署。所有build/deployment必须从Axiom执行仓库规定的`nixos-rebuild ... --build-host localhost`路径，禁止在Acorn运行任何Nix命令，也禁止从当前dirty worktree switch。
2. 选择maintenance window并先关闭旧RustDesk session。只记录approved metadata：hbbs/hbbr PID/start identity、active状态、21115-21117/TCP与21116/UDP listener、当前connection/byte基线和fallback可达性；不读取secret、key、RustDesk mutable config或完整environment。
3. Switch后按shared-package blast radius要求hbbs与hbbr都获得candidate executable/new identity并恢复active。只读取allowlist证据确认hbbs启动值为`ALWAYS_USE_RELAY=Y`、两个key preflight成功、hbbr listener恢复、firewall/SG及端口集合无漂移；不得把任一daemon恢复推断成另一个已恢复。
4. 证明Axiom、Charlie重新注册且pinned server key/auth仍工作。所有pre-switch connection都作废，从fresh controller建立新会话；旧session或自动reconnect不能作为candidate证据。
5. 在已复现问题的same-intranet拓扑中，至少完成每个受支持控制方向的fresh session：证明hbbs不再选择`FetchLocalAddr`，controlled端收到`PunchHole/SYMMETRIC`等价路径，hbbr出现对应new request、pairing与双向bytes；同时用redacted 5-tuple/socket或packet metadata证明endpoint之间没有获胜的direct data connection，实际payload连接只指向Acorn relay port。若无法安全观察消息类型，以“hbbr paired+bytes positive”和“endpoint direct established socket/bytes zero”作为不可缺少的data-plane组合证据。
6. 在同一fresh process/session identity下重做correct-password positive与wrong/old/cross-host negative controls，并验证画面与keyboard/pointer；认证拒绝必须与transport失败区分。任何pending ready/finalizer必须先重验其本地PID/start identity，不能用本patch绕过既有manual-finalize gate。
7. 运行代表性持续会话，记录不含ID/secret的latency、hbbr CPU/memory、connection count、per-session/total throughput、Acorn ingress/egress与Aliyun费用信号；指定owner、告警/费用阈值和stop condition。确认SSH、reverse-SSH、ToDesk可用，并演练非破坏性的operator containment路径。
8. 任一dual-service恢复、same-intranet direct negative、hbbr positive、auth或capacity gate失败时，不得声称force-relay runtime PASS。由于旧baseline会重新暴露same-intranet direct路径，正常containment应停止RustDesk新会话/关闭21117并保留fallback，再从新的clean change fixed-forward；不得在“所有流量经Acorn”的承诺下把旧行为重新启用为可用rollback。

### Review evidence and boundaries

- 独立检查`plan.md`、当前`docs/test-report.md`、RFC/review history、完整production diff、patch、pinned server 1.1.14与client 1.4.9相关control-flow、四份baseline/candidate generated units、`git status`、baseline/`origin/master`拓扑和recent history。
- `git diff --check`通过；HEAD、merge-base与`origin/master`均为`d85c80f3`，ahead/behind为`0/0`。Untracked patch由逐行内容与verifier的exact-byte/zero-fuzz证据覆盖。
- 本review未执行任何Nix命令，未在Acorn或其他host build/deploy，未启动/停止/restart服务，未建立session，未运行finalizer，未commit/push，也未读取secret plaintext/ciphertext payload、private/public key内容或RustDesk mutable config。
- 用户提供的1.1.14/1.1.15 same-intranet runtime observation用于确认问题与选择runtime gate；candidate的runtime修复仍标记为NOT RUN，未被本review冒充为独立runtime PASS。

### 会话注意力摘要

- **阶段**：`review-change`
- **阶段结论**：`PASS`
- **注意力等级**：`review`
- **判断变化**：上一轮仅environment change留下的same-intranet caveat已由最小source patch在静态control-flow上关闭；同时shared package使hbbr从“应保持PID”改为“必须按restart规划”。
- **关键发现**：1) `true`时跳过`FetchLocalAddr`并进入既有`PunchHole + SYMMETRIC` relay链，stable `false`完全保持旧表达式；2) 当前证据足够PR，不足以证明runtime data plane；3) private patch维护、dual restart及Acorn费用/DoS/单点是非阻塞但高影响残余。
- **阻塞项**：无。
- **残余风险**：升级/rebase需人工重审；hbbs/hbbr共同restart会中断会话；全量relay缺少failover和task-owned cost/connection circuit breaker；runtime same-intranet direct negative与hbbr positive尚未执行。
- **人类动作**：在merge前复核并记录对private patch维护责任、dual-service中断和Acorn费用/单点风险的接受，同时指定流量/费用owner与stop threshold。
- **自动下一步**：可创建PR并运行required checks；上述复核落盘前停止在merge，不得deploy。复核后从clean merged baseline执行本section runtime gates。
- **完整证据**：`.legion/tasks/rustdesk-self-hosted-remote-access/docs/review-change.md`；`.legion/tasks/rustdesk-self-hosted-remote-access/docs/test-report.md`；`hosts/acorn/patches/rustdesk-server-force-relay-intranet.patch`。

---

## Historical review — Acorn hbbs force-relay

### Findings

#### Blocking findings

无。

#### Non-blocking findings

1. **MEDIUM — Force-relay 让 Acorn/hbbr 成为持续数据面与费用依赖。** Production diff 只改变 hbbs 配置，但策略作用域是使用该 hbbs 的全部客户端；对走 1.1.14 常规 force-relay 路径的后续新会话，原本可 peer-to-peer 的流量将改经 Acorn，并在会话全程依赖 hbbr、Acorn 网络与 TCP 21117。Generated hbbr unit 没有 task-owned 带宽策略，因此保留 1.1.14 上游默认值：每条 relay connection 双向合计 16 Mb/s、全局 1024 Mb/s；它们是吞吐限制，不是云费用预算。单 relay host 还意味着 hbbr/Acorn 故障会中断 relay session。用户已显式接受这一取舍，`plan.md:35` 与 `docs/rfc.md:332,347` 也已记录费用/可用性风险，因此不阻塞 PR；部署仍需明确流量/费用 owner、观测和回退阈值。
2. **LOW — Build/source 只证明请求的 1.1.14 机制，不证明“任何拓扑都绝不会直连”。** Pinned 1.1.14 source 在 hbbs 启动时读取 `ALWAYS_USE_RELAY=Y`，并在常规 hole-punch 路径把消息改为 `NatType::SYMMETRIC`，使 1.4.9 client 选择 relay；它不会把已有会话追溯迁移到 relay。同一 server source 仍保留 same-intranet `FetchLocalAddr` 分支，且既有 loopback-only hbbs command interface 可在进程存活期间修改该 flag。两者都不是本 diff 新增，用户批准的也正是这套上游语义；但必须用 switch 后新建的 Axiom↔Charlie 会话完成 direct negative control 与 hbbr traffic positive proof。不得把 static PASS 扩大成 topology-independent 或 tamper-proof 承诺。
3. **LOW — Clean Acorn switch 会按设计 stop/restart hbbs，并可能短暂中断注册或建连。** 独立 eval 得到 `rustdesk-signal.stopIfChanged = true` 与 `restartIfChanged = true`；generated unit 已变化，因此 switch 应替换 hbbs process。hbbr unit byte-identical，不应仅因本变更重启。Acorn 不能直接改写 Charlie 本地 reservation/ready/stamp 或 launchd PID，但网络中断可能使 Charlie 暂时 offline；若 Charlie service/server PID 因间接原因漂移，pending ready 将失效。Switch 必须走 SSH/ToDesk 等 fallback，不能依赖被测 RustDesk session；任何 finalizer 前都要重验 Charlie 已批准的 state/PID identity。

### Verdict

**PASS — 可进入 Acorn force-relay PR；不是 deployment、runtime relay、带宽、可用性、Charlie state 或 remote-auth PASS。** 未发现阻塞 correctness、security、scope、regression 或 verification-evidence finding。任何 Acorn switch 前仍须 required checks、merge，并从 clean merged `origin/master` 执行。

> **Review target**: `origin/master` / HEAD `662575240a1d3117be3c1773a3b2f825f839aebf` 加当前未提交的 `hosts/acorn/default.nix` 单行实现与 verifier-owned `docs/test-report.md` evidence
> **Direct author**: `engineer-dapper-fox`
> **Verifier**: `verify-change-dapper-lemur`
> **Reviewer**: `review-change-zesty-raven`
> **Provenance**: author、verifier、reviewer 是不同派生事件；本 review 独立检查 candidate 与交付证据
> **Verification gate**: 当前 `docs/test-report.md` 对 exact differential eval/generated units、完整 Acorn toplevel build 与 pinned 1.1.14 source semantics 为 PASS；runtime/deployment NOT RUN
> **Security lens**: applied — routing/protocol boundary、server key/auth continuity、ingress、relay traffic concentration、local policy mutability 与 client pending-state interaction
> **RFC disposition**: 用户已显式批准 Acorn `ALWAYS_USE_RELAY=Y`、接受 stale RFC bypass 并禁止重开；该滞后不是设计 blocker，本 review 不修改 `docs/rfc.md`
> **Reviewed**: 2026-07-15

### Review results

1. **Scope、minimality 与显式 RFC bypass — PASS。** 写入本 review 前，唯一 production delta 是 `hosts/acorn/default.nix` 的一行 insertion；另一 changed path 是 verifier-owned `docs/test-report.md`。没有 Axiom、Charlie、module、package、firewall、`.age` ciphertext 或 RFC delta。Acorn 位于 `plan.md:51-57` scope 内。旧 Axiom-only implementation boundary 确实滞后，但用户已批准这项 exact force-relay change 且不再重开 RFC；本 review 没有把旧文字伪装成已对齐。
2. **Unit placement 与 1.1.14 semantics — PASS，保留上述 runtime boundary。** Option 位于 `systemd.services.rustdesk-signal.environment`；realized hbbs unit 恰新增一次 `Environment="ALWAYS_USE_RELAY=Y"`。hbbr option 没有该 attribute，realized unit 与 baseline byte-identical（`docs/test-report.md:23-30,39-45,49-60`）。Pinned official tag 中，hbbs 把 environment value 转大写，仅在等于 `Y` 时设置 global flag；常规 hole-punch 路径随后写入 `NatType::SYMMETRIC`，上游注释为 `will force relay`（`docs/test-report.md:92-113`）。这是 RustDesk Server 1.1.14 documented mechanism，归属 hbbs 而非 hbbr。
3. **Key、port、authentication 与 service hardening — PASS。** Exact differential evidence 证明 hbbs/hbbr package 1.1.14、两个 `ExecStart`、`--relay-servers rustdesk.0xc1.wang`、`-k _`、三项 `ExecStartPre`、shared key preflight、private/public key path 与 metadata、service user、restart policy 和 `LimitCORE=0` 均未改变。`openFirewall=false`、完整 TCP/UDP list 与 RustDesk 暴露仍是 TCP 21115-21117 + UDP 21116；21114/21118/21119 仍未开放（`docs/test-report.md:25-27,51-82`）。没有 secret source/value/decryption path、key rotation、password path、authentication option、listener 或 trust material 变化。本 reviewer 未读取 secret payload 或 key content。
4. **Acorn activation 与 Charlie pending-state interaction — PASS，属于有界 deployment risk。** Changed hbbs unit 加 `stopIfChanged/restartIfChanged=true` 意味着 clean switch 应只 stop/start `rustdesk-signal`；unchanged hbbr unit 应保持原 process。它可能短暂打断 hbbs registration 与新建连接，但不会自行改变 Charlie Nix revision、触发 Charlie provision、消耗另一次 password attempt 或修改 `/var/db/rustdesk-provision`。Charlie ready 绑定的是 Charlie 本地 privileged-service/user-server PID 与 start identity（`hosts/charlie/default.nix:1462-1506`），不是 Acorn hbbs PID。因此，orchestrator 提供的 current reservation/ready 只有在这些 Charlie identity 保持不变时才继续 structurally valid。任一 identity 漂移都应让 finalizer fail closed；current attempt 仍视为已消耗，并继续遵守既有 fixed-forward rule。Force-relay 前的 auth observation 不能证明新 transport policy，必须在 switch 后 fresh session 上重做。
5. **Relay bandwidth、费用、容量与单点风险 — 已接受，但运营 attention 仍 OPEN。** Force-relay 把常规 session bytes 与 connection metadata 集中到 Acorn，并把 hbbr/Acorn saturation、packet loss、compromise、cloud egress abuse 的影响放大。当前唯一 relay hostname 指向同一 Acorn deployment，本 change 没有 failover relay。Upstream hbbr defaults 是宽松 throughput limit，不是 task-specific quota 或 cost circuit breaker。该 accepted risk 不阻塞 PR，但 runtime closeout 必须留下代表性流量/费用观测、明确 owner 与 containment threshold。
6. **Verification sufficiency — PASS for PR entry。** Verifier 不只 parse/grep 这一行：clean-HEAD/candidate option equality、exact generated-unit differential、unchanged hbbr identity、key/firewall regression assertions、完整 dirty-source Acorn toplevel realization + `--rebuild`、closure 与 exact unit/package linkage，以及 pinned source 对 official 1.1.14 tag 的 byte comparison 全部 PASS（`docs/test-report.md:32-113`）。本 review 另行复核 scope/whitespace、realized units、pinned source、hbbs-only delta，并 eval `stopIfChanged/restartIfChanged`。这些证据足以支持 minimal NixOS change 进入 PR；build 不能启动 hbbs、观察 switch transaction、证明注册恢复、区分 fresh relay/direct、测量带宽或证明 Charlie state continuity。

### Security assessment

Security lens 未发现新增 authentication、secret、key、permission 或 ingress regression。新增值只是 existing hbbs service 上的 public boolean environment setting；它不增加 credential、不改变 server keypair/key preflight/`-k _`、不开放端口，也不修改任何 client。既有 relay protocol 与 public port 均未变化。真正改变的是风险集中度：更多 traffic 与 metadata 经过 Acorn/hbbr，因此 server compromise、DoS 与 billing abuse 的后果更大。Upstream loopback command 原本就能修改 in-memory relay flag，但本 diff 既未把该 command 暴露到 remote，也未扩大 local access。在已批准的 Acorn trust model 与显式 risk acceptance 内，没有发现新增可利用的 trust-boundary bypass。

### Residual clean-merge runtime gates

1. 创建 PR、完成 required checks、merge，并刷新 clean `origin/master`；不得从当前 dirty worktree switch Acorn。
2. Switch 前只记录 approved Acorn/Charlie state：Acorn hbbs/hbbr active identity 与 listener metadata；若 Charlie 有 pending ready，则记录 reservation/ready/stamp state 及两项 ready-bound local PID/start identity。不得 dump secret、key、mutable RustDesk config 或完整 process environment。
3. 使用 SSH 或其他 preserved fallback 执行 switch。证明 hbbs 获得新 process/invocation identity、以 `ALWAYS_USE_RELAY=Y` 启动、通过既有 key preflight 并恢复 active；证明 hbbr 保持同一 process identity，listener/firewall/SG exposure 没有变化。
4. 证明 Charlie 与 Axiom 重新注册。若 Charlie 有 pending ready，重验其 exact local identity；任何 Charlie PID/start drift 都会使 ready 无效，此时不得 finalize/reset/rollback，应停止并走既有 fresh-revision fixed-forward。
5. 关闭所有 pre-switch RustDesk session，再建立 fresh Axiom↔Charlie session。用 approved connection/byte metadata 证明 hbbr 承载该会话，且没有 endpoint-to-endpoint data connection 胜出；若运营承诺需要覆盖 same-intranet topology，须单独测试该分支。
6. Force-relay 后重做 correct-password positive 与 wrong/old/cross-host negative controls；只有全部通过且 Charlie ready identity 仍 current，才可进入 exact manual finalizer。
7. 在代表性会话中观察 latency、hbbr CPU/memory、per-session/total throughput、Acorn ingress/egress 与 Aliyun cost，明确 owner 与 containment threshold。异常时停止新会话；紧急 containment 可关闭 21117，正常 rollback 则从另一 clean merged change 移除 environment line，并在 hbbs 重启后建立 fresh session 复核。
8. 保留并证明 SSH、reverse-SSH、ToDesk fallback；follow-up evidence PR 不得包含 secret/key/config content。

### Review evidence and boundaries

- 独立检查 `plan.md`、当前 `docs/test-report.md`、RFC/history、完整 production diff、generated hbbs/hbbr units、pinned RustDesk Server 1.1.14 source、Charlie finalizer identity checks、`git status`、`git diff --check`、baseline topology 与 recent history。
- 独立确认 generated hbbs unit 只新增 `Environment="ALWAYS_USE_RELAY=Y"`，generated hbbr unit 不含该 variable。Read-only Nix eval 返回 `rustdesk-signal.stopIfChanged=true`、`restartIfChanged=true` 与 `ALWAYS_USE_RELAY="Y"`。
- 把任何 current Charlie reservation/ready/PID 视为 orchestrator-supplied context；本 reviewer 未连接 Charlie 或 Acorn production，也不声称独立观察了 current mutable state。
- 未读取 secret plaintext/ciphertext payload、private/public key content 或 RustDesk mutable config；未修改 production code 或 RFC；未 commit、push、deploy、switch、restart service、建立 session、运行 finalizer 或改变 remote state。

### 会话注意力摘要

- **Attention state**：OPEN for post-merge runtime、relay cost/capacity 与 Charlie identity continuity；**CLOSED for RFC/design**。它不阻塞本次 `review-change` PASS 或 PR creation。
- **已明确处置**：用户已批准 Acorn `ALWAYS_USE_RELAY=Y` 并要求继续，且明确不再重开 RFC；RFC implementation-boundary 滞后是已批准 bypass，不得再次作为 design blocker，也不得把旧 RFC 文字冒充当前实现描述。
- **本轮已关闭**：单行 scope、hbbs-only placement、1.1.14 upstream hook、hbbr generated-unit identity、key/port/auth/firewall regression、security lens 与 pre-merge build/source evidence sufficiency。
- **仍需关闭**：required checks/merge、clean Acorn switch、hbbs-only restart、hbbr continuity、Axiom/Charlie re-registration、Charlie ready-bound PID continuity、fresh-session forced-relay positive/negative evidence、remote-auth 正负测、代表性带宽/费用与 fallback。
- **禁止动作**：从当前 worktree switch、把 build/source PASS 写成 runtime relay PASS、把旧 session 当作 force-relay evidence、在 Charlie PID/ready 失效时 finalize/reset/rollback、读取 secret/key/config content，或在没有流量/费用 owner 与 stop threshold 时宣称运营风险已关闭。

---

## Historical review — Charlie user-server runtime fixed-forward

### Findings

#### Blocking findings

None.

#### Non-blocking findings

1. **LOW — Exact recovery control flow has not yet run end-to-end as part of a candidate activation.** The verifier exercised the exact generated `postActivation` with syntax, lint, ordering and structural assertions, while the supplied target observation proves that the same manual `bootstrap` repaired the missing user job (`docs/test-report.md:28-44,91-105`). It did not switch or activate the candidate. This is an honest deployment evidence boundary rather than a pre-merge defect: both the no-GUI skip and active-GUI recovery branch must be observed during the first clean merged Charlie switch, before runtime/finalization is called PASS.
2. **LOW — The `print` then `bootstrap` recovery has a narrow concurrent-load race.** Sequential runs are idempotent: an existing job is not bootstrapped again, `kickstart` without `-k` does not replace a running instance, and an absent GUI domain is a successful no-op (`hosts/charlie/default.nix:1697-1716`). If another actor loads the same label after the negative `print` but before `bootstrap`, `bootstrap` can fail even though the job has appeared, making activation fail closed. This does not expose a secret, execute as root, or permit false readiness. If the race is ever observed, the minimal hardening is to accept a failed `bootstrap` only after an immediate `launchctl print` confirms the exact label now exists; it does not need to block this PR.

### Verdict

**PASS — ready for the Charlie runtime-fix PR and, after required checks and merge, entry into the Charlie deployment phase from a clean merged `origin/master`; not a runtime-auth or manual-finalization PASS.** No blocking correctness, security, scope, regression or verification finding was found. The current dirty feature worktree is not an authorized deployment source.

> **Review target**: `origin/master` / HEAD `2de54e09ed907defb3b116dea7c9d29429a40c41` plus the current uncommitted `hosts/charlie/default.nix` and verification-report diff
> **Direct author**: `engineer-swift-marten`
> **Verifier**: `verify-change-swift-ferret`
> **Verification gate**: current `docs/test-report.md` PASS for exact generated artifacts, full remote `aarch64-darwin` build and signed store bundle; candidate activation/runtime NOT RUN
> **Security lens**: applied — root activation, user-domain plist loading, IPC metadata, runtime secret boundary, revision/state reuse, operation lock and one-attempt/manual-finalize state machine
> **RFC disposition**: the user explicitly bypassed the stale “Charlie unchanged” amendment and required continuation without another RFC; that process lag is not a review blocker and this review does not modify `docs/rfc.md`
> **Reviewed**: 2026-07-14

### Review results

1. **Scope, minimality and explicit process bypass — PASS.** Before this review artifact, the only production path is `hosts/charlie/default.nix` at `+30/-9`; the other changed path is verifier-owned `docs/test-report.md`. There is no Acorn, Axiom, module, package, or `*.age` delta. The production changes are limited to the two duplicated validator expectations, one revision marker and a 21-line active-GUI recovery block. Charlie remains inside `plan.md:51-57`; the older Axiom-only RFC text is explicitly bypassed by the user's current rollout decision rather than silently treated as aligned.
2. **`501:0` metadata correction and `wheel_gid=0` — PASS.** The supplied target evidence records `/tmp/RustDesk-501`, `ipc` and `ipc.pid` as `501:0`, and records that the v7 primary-GID expectation failed before reservation while manual job bootstrap restored IPC (`docs/test-report.md:91-99`). The candidate derives UID with `id -u c1` but requires numeric group 0 for all three objects (`hosts/charlie/default.nix:758-778,1374-1391`). On supported macOS, wheel is the built-in GID 0; using the numeric kernel identity is appropriate for `stat -f %g` and matches the observed target. A platform drift would reject readiness before secret access rather than broaden acceptance.
3. **Symlink, type, owner and mode resistance — PASS.** Both provision and finalizer still require a non-symlink directory at exact `<uid>:0:0700`, a non-symlink socket at exact `<uid>:0:0600`, and a non-symlink regular PID file at exact `<uid>:0:0600`. The diff adds no `chmod`, `chown`, repair, fallback group, wildcard owner, or user-controlled path. PID bytes, launchd top-level job shape, PID equality, process UID/command/executable, `lsof` executable/socket binding, and stable start identity remain intact (`hosts/charlie/default.nix:779-819,1392-1428`). Changing primary GID to exact 0 therefore narrows the accepted real shape and does not weaken the existing fail-closed checks. Existing user-owned-directory race residuals remain inside the approved single-owner endpoint boundary and are not expanded by this diff.
4. **LaunchAgent recovery ordering, trust and no-GUI behavior — PASS with the LOW race above.** Independent evaluation of the exact candidate activation shows the managed app transaction first, then the generated launchd phase compares the candidate store plist, removes a destination symlink if present, copies `/Library/LaunchAgents/com.carriez.RustDesk_server.plist`, and invokes the existing load path; only later does `postActivation` pass the current-boot agenix revision gate and run the new recovery. Thus the fixed path is populated from the evaluated candidate before the fallback bootstrap. The bootstrap target is `gui/<c1 uid>`, so the agent executes in c1's user domain, not as root; it does not enlarge the privileged LaunchDaemon or root executable trust boundary. A pre-existing same-label user job can at worst cause fail-closed readiness/availability under the declared trusted-c1 model: provision still requires the exact signed RustDesk path, arguments, UID, PID, socket and executable before reaching the secret. If `gui/<uid>` does not exist, the outer probe skips bootstrap and kickstart without an error, preserving headless/login-window activation and leaving provision retries pre-reservation.
5. **Idempotence and process preservation — PASS.** Re-running activation with a loaded label takes only the non-destructive `kickstart` path; the absence of `-k` is intentional because activation must ensure demand, not invalidate a running server identity. A missing label is bootstrapped once and then kicked. Failures are surfaced rather than hidden, while an absent GUI domain is the only deliberate no-op. This avoids an activation-driven server replacement racing the provision state machine; the later provision helper remains the sole code that uses `kickstart -k` after password ACK and requires both service and server PID replacement (`hosts/charlie/default.nix:1096-1111`).
6. **Fresh revision and old-state non-reuse — PASS.** `provision=charlie-rustdesk-provision-v7` becomes `v8` inside the composite hash while `charlie-rustdesk-provision-v4:` remains the parser prefix (`hosts/charlie/default.nix:309-318`). Exact evaluated values change from `1dd4…26ee0` to `651a…be26`, so v7 stamp/reservation/ready values cannot compare current, but remain syntactically legal stale objects (`docs/test-report.md:46-60`). Both service and user-agent plists carry the new composite value and the provision derivation itself changes. Provision may replace only legal stale state under the existing ordering; finalizer requires current v8 reservation, ready and live identities and therefore cannot finalize v7 state. Malformed type, metadata or content still fails closed.
7. **Root activation, secret boundary and state machine — PASS.** The recovery block contains no secret path, config read, password argument, state deletion or finalizer call. It runs after the agenix current-revision/current-boot gate, while the provision daemon independently rechecks that gate before reservation, before secret resolution and before password invocation (`hosts/charlie/default.nix:966-1074,1681-1716`). Merely making the c1 agent available cannot bypass public-config, signed-app, privileged-service, user-process, IPC or identity gates. Provision and finalizer continue sharing the root-owned empty-directory operation lock; current reservation still means `attempt-used`; reservation is atomically published and synced before the secret is read; ready is published only after ACK, double PID replacement and public proof; finalizer remains zero-secret and requires explicit confirmation plus current live identities (`hosts/charlie/default.nix:463-545,975-1135,1177-1254,1477-1508`). The accepted short-lived password argv/crash-metadata residual is unchanged.
8. **Generated artifacts, remote Darwin build and deployability — PASS for PR/deployment entry.** Verification used the evaluated provision, finalizer, `postActivation` and full activation rather than source-only snippets; all four passed `bash -n`, focused scripts had zero ShellCheck findings, and full-activation diagnostics introduced no candidate finding. Differential assertions prove that each validator changed only the GID expectation and that recovery follows agenix gate → UID → GUI probe → job probe/bootstrap → kickstart. The exact dirty-source system derivation was fully realized in Charlie's remote store as `/nix/store/3yl4galgkg4xzpkn7nlsl7v9awjnpq46-darwin-system-25.11.ebec37a`; its sole RustDesk 1.4.9 bundle passed arm64, bundle/version, deep/strict codesign, Team ID and Gatekeeper notarization checks on Darwin (`docs/test-report.md:28-89`). This is sufficient to merge and then attempt a controlled deployment. It does not substitute for candidate activation, destination-app verification, launchd runtime, TCC, remote-auth controls or manual finalization.

### Security assessment

The security lens found no exploitable trust-boundary expansion. Root activation uses fixed absolute tools and a fixed system-managed plist path, and bootstraps only c1's GUI domain. Exact generated ordering places the evaluated plist before recovery; the loaded process remains UID c1 and must later satisfy signed-path, launchd, PID, executable and socket checks. The metadata change accepts the one observed platform shape but retains stricter-than-primary-group numeric ownership and exact modes. No secret source, decryption path, plaintext, ingress, root LaunchDaemon program, app payload, TCC grant, operation-lock rule, attempt rule or finalizer rule changes. Under the task's explicit single-owner trusted-endpoint model, a c1-controlled same-label collision is an availability/readiness failure, not a root privilege or secret bypass.

### Residual clean-merge deployment gates

1. Create the PR, run required checks, merge, and refresh a clean `origin/master`; never switch Charlie from this dirty worktree or a detached verification tree.
2. Before switch, reconfirm only approved state metadata: v7 has no current stamp/attempt/ready. Do not read the secret or RustDesk mutable config, run an old finalizer, reset state, or activate an older generation.
3. During switch, retain the generated ordering proof: verified destination app and candidate plist precede recovery. If no `gui/501` domain exists, activation must still succeed and no reservation may appear until valid runtime exists. If it exists, prove the exact user job, UID 501 process, `501:0` directory/socket/PID metadata, exact executable/arguments and stable IPC.
4. Prove exactly one v8 attempt, a current reservation plus current ready and no stamp; prove both auth-serving PIDs were replaced after ACK and that the operation lock is absent after successful provision. Any pre-reservation readiness failure remains retryable; any current reservation without valid ready is consumed and requires stop plus a fresh fixed-forward revision.
5. Verify `/Applications/RustDesk.app` destination signature/Team/Gatekeeper, public host/key/options, TCC Screen Recording/Accessibility/Input Monitoring, actual screen and keyboard/pointer control, and the preserved SSH/reverse-SSH/ToDesk fallback.
6. From a fresh controller, pass the new-password positive test and wrong/old/cross-host negative tests. Only then run the exact manual finalizer and prove current stamp, ready removal, fast-skip and no second password invocation.
7. On any post-reservation failure, stop the RustDesk jobs, do not finalize/reset/roll back, and fixed-forward with another fresh revision. Record runtime evidence in the follow-up evidence PR without secret or mutable-config contents.

### Review evidence and boundaries

- Independently inspected the complete production diff, `git status`, scope, `git diff --check`, plan, current test report, existing review/RFC history, both validator copies, launchd plists, activation ordering, revision inputs, provision/finalizer lock and state transitions.
- Independently evaluated the exact dirty candidate's full activation text and confirmed managed-app activation precedes generated plist copy/load, which precedes agenix-gated recovery. No activation output was executed.
- Treated `501:0`, manual-bootstrap success and v7 no-state facts as explicitly labeled orchestrator-supplied runtime evidence, not as this reviewer's independent observation.
- Did not read secret plaintext/ciphertext contents or RustDesk mutable config; did not modify production code or RFC; did not commit, push, deploy, switch, start/stop a service, run a finalizer, or alter remote state.

### 会话注意力摘要

- **Attention state**：OPEN for PR/deployment runtime evidence, **not** for RFC/design. It does not block this `review-change` PASS or PR creation.
- **已明确处置**：用户已显式要求继续 Charlie rollout 并 bypass 旧 RFC 的“Charlie不变”；不得再以该流程滞后要求新 RFC，也不得把旧文字冒充当前设计授权。
- **本轮已关闭**：`501:0` validator correctness、wheel GID 0、symlink/type/owner/mode防线、active-GUI recovery的顺序/幂等/信任边界、v8 stale-state隔离、root secret/lock/attempt边界，以及pre-merge build/signature证据充分性。
- **仍需关闭**：required checks/merge、clean merged switch、exact recovery branch、v8 one-attempt/ready、destination signature、TCC、真实远程认证正负测与manual finalize。
- **禁止动作**：从当前worktree直接switch、把build PASS写成runtime PASS、读取secret或mutable config内容、在外部认证前finalize、reset已消耗revision、或rollback到旧generation。

---

## Historical Axiom fixed-forward review — findings

### Blocking findings

None.

### Non-blocking findings

1. **LOW — Some task status text still points at the superseded Round 8 gate.** `docs/rfc.md:4,391-414`, `docs/research.md:6,218,238`, and `tasks.md:5-7` still say that a fresh RFC review is pending or that Round 8 FAIL is current, although `docs/review-rfc.md:1-21` records the current Round 9 design PASS. In addition, `docs/research.md:50-54` calls the root-preserving combination a “proven conjunction,” while `docs/review-rfc.md:13-15,25` correctly says that exact combination remains a deployment hypothesis. This is conservative or locally imprecise rather than an unsafe rollout claim: the authoritative test report (`docs/test-report.md:3-12,111-123`) and this review explicitly leave candidate runtime unproved. Update those status/index sentences before or with the PR so future operators do not have to infer precedence.
2. **LOW — The exact NixOS switch transition was reasoned from pinned implementation and current unit state, not executed as a candidate lifecycle test.** The report exercises generated units and the provision state machine (`docs/test-report.md:24-40`) but does not emulate `rustdesk.service=inactive` plus `rustdesk-provision.service=active/exited`. Read-only review confirmed those current states and an active `multi-user.target`; the locked NixOS switcher stops and starts an active changed service, and the changed provision unit pulls the main service through `Wants=`/`After=` (`hosts/axiom/default.nix:1569-1584`). This leaves no realistic pre-merge skip/double-run defect, but the actual switch output, unit invocation count, and one-attempt state must be captured in the post-merge runtime evidence.

## Verdict

**PASS — ready for the Axiom-only hotfix PR, not for deployment or finalization.** No blocking correctness, security, regression, scope, or verification finding was found.

> **Review target**: `origin/master` / HEAD `0026eb9922c87e9624ed7352b09b58cddb1a45a3` plus the current uncommitted hotfix/documentation diff
> **Design gate**: Round 9 `PASS — design only`
> **Verification gate**: current `docs/test-report.md` static/generated/state/full-build PASS; candidate runtime NOT RUN
> **Security lens**: applied — root service/session coupling, immutable plugin loading, secret use, revision/state transition, finalizer identity, and fixed-forward/rollback boundaries
> **Reviewed**: 2026-07-13

## Review results

1. **Resolver direction, scope, and canonical config — PASS.** `networking.hosts.${acornPublicIp} = [ rustdeskHost ];` is the correct IP-to-hostnames direction (`hosts/axiom/default.nix:1501-1504`), and the generated hosts file is `8.159.128.125 rustdesk.0xc1.wang`. The public configuration still writes and proves `rustdesk.0xc1.wang` for both host and relay (`hosts/axiom/default.nix:231-266,821-843`); the public IP is only the Axiom NSS target. No client ingress, Acorn, or Charlie resolver change is present.
2. **Root storage and child environment boundary — PASS with runtime gate.** The root unit retains `HOME=/root` and `XDG_CONFIG_HOME=/root/.config`, declares no `XDG_DATA_HOME`, and keeps the generated immutable-store `PATH` rather than adding `/run/current-system/sw` (`hosts/axiom/default.nix:166-178,1543-1566`). The password CLI separately remains in `/root` and `/root/.config` (`hosts/axiom/default.nix:304-313,614-632,954-960`). No production addition copies, moves, removes, chowns, or points root RustDesk storage at c1 state. Upstream may override or conditionally preserve values while spawning c1 through `sudo`; therefore the unit text is not treated as child proof. The required live child allowlist check remains explicit in `docs/test-report.md:117-123`.
3. **Wrapper composition and PipeWire closure — PASS.** The RustDesk wrapper prefixes GStreamer core and `gst-plugins-base`; the unit-provided immutable `${pkgs.pipewire}/lib/gstreamer-1.0` is consequently appended, not substituted for those paths (`hosts/axiom/default.nix:175,1554`). The exact unit directly references the PipeWire store output, `libgstpipewire.so` exists in that output, the toplevel closure retains it, and exact-path `gst-inspect-1.0` resolves `pipewiresrc`, `videoconvert`, and `appsink` (`docs/test-report.md:34-39,70-90`). Child receipt of the composed value remains a runtime gate.
4. **Composite revision and stale-state legality — PASS.** The hash adds a fixed runtime-contract marker, the canonical resolver tuple, and deterministic `builtins.toJSON` serialization of the shared eleven-value environment (`hosts/axiom/default.nix:287-303`). Those inputs contain only public constants and immutable store paths; the existing secret input remains a ciphertext store-path identity, not plaintext. The digest changes from `bea8…10a` to `bf93…9b8`, while `axiom-rustdesk-provision-v4:` remains unchanged, so the deployed reservation/ready parse as legal stale objects rather than malformed state (`docs/test-report.md:63-68`).
5. **Stale reservation/ready ordering and finalizer rejection — PASS.** Provision proves runtime/public state, publishes and syncs the new reservation, removes and syncs stale ready, revalidates runtime, and only then resolves/reads the secret and calls `--password` (`hosts/axiom/default.nix:859-960`). The candidate finalizer requires a current reservation and current ready before checking live identities and publishing a stamp (`hosts/axiom/default.nix:1356-1386`), so old state cannot finalize. Exact generated-script differential checks show no state-machine logic change beyond revision identity, and the isolated transition test proves stale replacement, one-attempt behavior, and old-state finalizer rejection (`docs/test-report.md:36-38,80-90`).
6. **Activation/restart behavior — PASS with bounded operational residual.** The currently active/exited `RemainAfterExit` provision unit changes both `ExecStart` and `X-Restart-Triggers`; locked NixOS switch semantics therefore stop it before activation and start it after daemon reload. Its start transaction pulls the currently stopped main service through `Wants=rustdesk.service` and orders provision after it. The active `multi-user.target` also re-evaluates wanted dependencies. Concurrent requests are coalesced by systemd, and `RemainAfterExit` makes a later start a no-op. Under normal process-interruption and orderly-reboot semantics, a repeated switch cannot cause a second password call after reservation publication because the operation lock and current-reservation branch fail closed. Sudden storage/controller uncertainty remains a stop-and-fixed-forward condition. Other realistic failures are missing session/runtime readiness or a failed dependency; these either leave RustDesk stopped or fail before reservation, and still require runtime observation rather than a success claim.
7. **Scope and documentation claims — PASS.** Before this review artifact, the diff contains six task-local documents and only one production file, `hosts/axiom/default.nix`. There is zero diff under `hosts/acorn/**`, `hosts/charlie/**`, `modules/**`, `packages/**`, or any `*.age` file. Charlie remains explicitly blocked until Axiom manual finalize (`docs/test-report.md:111-123`). The current authoritative report repeatedly says no candidate switch, start, authentication, capture/input, secret read, or finalization occurred; aside from the LOW wording drift above, it does not claim candidate runtime success.
8. **Verification sufficiency — PASS for pre-merge claims.** Exact option evaluation, generated hosts/unit/scripts, wrapper/closure/factory execution, base/candidate revision comparison, isolated stale-state transitions, and a fresh full Axiom toplevel build directly cover the implementation claims (`docs/test-report.md:22-109`). Historical unchanged package/public-IPC/state-machine evidence remains applicable because generated provision/finalizer logic is byte-equal after normalizing only revision identity. Runtime-dependent child inheritance, NSS/NAT behavior, mutable-state ownership, graphics, authentication, and finalization are clearly excluded from the PASS.

## Security assessment

The hotfix adds no secret source, decryption path, password call, privilege transition, public port, or mutable migration. Session bus/runtime coordinates intentionally couple the root service to the trusted c1 graphical session, but they do not authorize c1 persistent storage and remain within the approved single-owner endpoint boundary. The only new plugin directory is an immutable Nix store path. Existing transient password-argv/crash-metadata residuals are unchanged. No exploitable trust-boundary expansion or secret leakage was found.

## Residual post-merge runtime gates

1. Merge/checks first; use a clean merged `origin/master` descendant of `0026eb99`, with RustDesk still stopped.
2. Reconfirm old reservation/ready are legal stale/identity-invalid, with no stamp; do not resume, reset, run an old finalizer, or roll back a generation.
3. During switch, observe the changed provision unit run once and pull the candidate main unit; prove one new-revision password attempt, fresh current reservation + ready, no stamp, and stable fresh process identities.
4. Compare only approved root/c1 path metadata before and after; require root canonical state to remain `root:root` and no c1 ownership migration.
5. Read only the approved root and c1 child environment keys. Prove actual child values and the composed core/base/PipeWire path; do not infer inheritance from the parent unit.
6. Prove canonical NSS resolution to `8.159.128.125`, exclusion of Clash fake-IP, and UDP 21116/TCP 21115 NAT behavior while public config remains canonical.
7. Post-ready only, prove the actual Wayland socket, c1 bus, portal, PipeWire stream/node, GStreamer factories, screen capture, and keyboard/pointer control.
8. Run correct-password positive and wrong/old/cross-host negative controls from a fresh controller; only then run the exact manual finalizer and prove stamp/fast-skip/no-second-attempt.
9. Any post-ready failure consumes the revision: stop RustDesk, do not finalize/reset/rollback, and fixed-forward again. Charlie remains blocked until Axiom finalizes successfully.

## Review evidence and boundaries

- `git diff --check origin/master`: **PASS**.
- Read-only current-state inspection confirmed Axiom main `inactive/dead`, provision `active/exited`, and `multi-user.target` active; no unit was started, stopped, restarted, or changed.
- No secret plaintext/ciphertext content or RustDesk public-key value was read or recorded. No production code, service state, finalizer state, deployment, commit, push, or PR was changed by this review.

---

## Historical configuration-PR review — preserved, superseded for the current hotfix

The review below applies to the original configuration PR ending at `3db55d1c`. It remains historical evidence and is not approval of the Axiom fixed-forward candidate or its runtime behavior.

# Review Change: RustDesk self-hosted remote access

> **Verdict**: **PASS - ready for the configuration PR**
> **Review target**: `origin/master` `0d61c714` through feature HEAD `3db55d1c`
> **Scope**: Configuration readiness only; production deployment remains gated
> **Security lens**: Secret handling, root services, IPC/process identity, signed app lifecycle, ingress, state publication, rollback
> **Date**: 2026-07-12

## Findings

No blocking correctness, security, scope, or maintainability finding remains.

The final review covered all five feature commits, the Round 7 RFC, generated helpers, failure/state tests, and target-native Charlie evidence. The branch was clean, rebased on live `origin/master`, ahead 5/behind 0, and passed `git diff --check`.

## Review Results

- **Source and artifacts**: Axiom source and cargo vendor are both pinned to RustDesk 1.4.9. Charlie pins the official ARM64 1.4.9 DMG and validates bundle id, Team ID, deep/strict signature, and Gatekeeper origin.
- **Acorn topology**: RustDesk Server 1.1.14 uses a separate agenix key, fail-closed key preflight, `-k _`, and only TCP 21115-21117 plus UDP 21116.
- **Provision state machine**: Reservation is durably published before secret access. Password invocation is one-shot and requires exact `Done!\n`; both auth-serving processes are replaced, public state is re-proved, and provision publishes ready but never stamp.
- **Manual finalization**: Finalizers require exact `--confirm-remote-auth`, share the operation lock, revalidate reservation/ready/process identities, read no secret, and invoke no password API.
- **Service lifecycle**: Axiom provision has only `Wants=` and `After=` on the main service and preserves replacement-capable `ExecStop`. Charlie app activation is locked, signature-gated, rollback-aware, idempotent for an identical verified bundle, and unloads old provision before transitions.
- **Security result**: PASS within the approved single-owner/manual-finalize threat model. No unaccepted secret exposure, privilege-boundary bypass, artifact-substitution path, or false rollback claim was found.

## Evidence

- Final Acorn output: `/nix/store/lbhi1fgapnhqj3z9xsajbcqg1bp17l8s-nixos-system-acorn-25.11.20260630.b6018f8`.
- Final Axiom output: `/nix/store/vq8y7x0bi84cpx9hp3yfcg82d6niy8pf-nixos-system-axiom-25.11.20260630.b6018f8`; effective RustDesk is 1.4.9.
- Final Charlie output: `/nix/store/9g2l5777jh51q9wzrr5yvywymgz6pmym-darwin-system-25.11.ebec37a` built on Charlie from exact commit `3db55d1c`.
- Charlie final system references `/nix/store/ll7kiyvhxzqs0j9clqf66a08s262szq0-rustdesk-macos-1.4.9/Applications/RustDesk.app`: arm64, version 1.4.9, bundle id `com.carriez.rustdesk`, Team `HZF9JMC8YN`, valid Notarized Developer ID signature and expected origin.
- Generated launchctl parser passed real complete Charlie output for two-argument server and three-argument service shapes while ignoring nested coalition state. Generated scripts, state/failure matrices, fallback controls, and finalizer zero-secret assertions passed.

## Deployment Gates

1. Deploy only from the clean merged commit, never a feature or Charlie verification worktree.
2. Verify DNS, Aliyun security group allow/deny rules, Acorn listeners/keypair/services, and relay ownership.
3. Verify actual systemd/launchd lifecycle, Charlie destination signature, PID replacement, and public configuration.
4. From a fresh controller, prove the new password succeeds and old, wrong, and cross-host passwords are rejected before root runs `rustdesk-provision-finalize --confirm-remote-auth`.
5. Validate Wayland, TCC, Aqua/LoginWindow, sleep, and FileVault behavior.
6. After any reservation exists, failure means RustDesk stopped plus fixed-forward to a fresh revision; never activate an older generation.
7. The accepted transient password argv and possible non-core crash-metadata exposure remain in force.

---

## Current Axiom PID-stability follow-up — 2026-07-13

### Findings

- **Blocking:** None.
- The 30-second dwell snapshots and then revalidates both main/server PID plus start identity in each pre-password and post-restart `wait_runtime`; it rejects the observed approximately 27-second server replacement while retaining every later fail-closed PID check.
- A normal successful provision adds 56 seconds over the two former 2-second dwells. Under repeated near-ready churn, `TimeoutStartSec=8min` is the effective cap rather than all 60 full dwells; that bounded timeout remains state-safe (pre-reservation failure is retryable, post-reservation failure remains fixed-forward only).
- The v8 marker and serialized dwell value produce `axiom-rustdesk-provision-v4:cdaeca40df2b16a3bc07e4614411fce472e892db744d987fc495995c270ab62c`; the unchanged v4 prefix keeps prior reservation/ready objects legal stale state. Scope is one Axiom production file, with no secret, trust-boundary, privilege, ingress, or finalizer change. Security lens applied.

### Verdict

**PASS — ready for the Axiom-only PID-stability hotfix PR, not for deployment or finalization.** The supplied generated-script, ShellCheck, isolated-state, and full-build evidence (`/nix/store/vrmh1rbjrn3lgw05gp4ldcz1rrzk2zx6-nixos-system-axiom-25.11.20260630.b6018f8`) is sufficient for this minimal diff; live readiness and remote-auth gates remain outstanding.
