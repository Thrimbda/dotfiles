# RFC 审查（round 2）：Azar 上 Const X 原生 Auth Mini 部署

审查范围仅限当前任务的 `plan.md`、`tasks.md`、`log.md`、`docs/research.md`、`docs/rfc.md`，并对照 `docs/review-rfc-round1.md`。本轮将补充证据视为已知事实：Axiom 当前 `nixos-rebuild --help` 已确认 `--specialisation` 可进入/切换 specialisation，而不带该 flag 的普通 `switch` 回到 base。此为设计审查，不构成目标 release、Nix eval 或生产 rollout 的实际验证。

## Verdict
FAIL

## Findings

### F1：`configure-auth` 的运行时状态保全契约仍未成为 release gate

> [REVIEW:blocking] RFC 已正确淘汰 Nix shell/TOML 文本 patch，并把 G1/G2 的启动前操作收敛为只读 `configure-auth --check`；但它仍只宣称目标 release 使用“Config/TOML 原子 writer”。这没有定义或预注册该 command 必须操作与 `constxd serve` 相同的运行时 config、enable/disable 的幂等与拒绝语义、以及非 `[auth]` 运行时配置和秘密引用不会被改写的可验证证据。
>
> [STATUS:open]

定位：任务验收把“不覆盖已有运行时配置或秘密”与稳定 enable/check/disable 明确列为必要条件，而 RFC 的 command 定义只给出三个调用形态和“原子 writer / check 不写文件”的概述；G0 的首次写入、G2 到 G1 到 G0 rollback 都依赖同一未被预注册的行为。D1 只验证 enabled、401、ingress 与登录，D3 只在既有 provider 尚可用时检验实际 `tool-result`，均不能证明 helper 未在写入前破坏其他运行时状态。

影响：若 command 选错 service 的 config 环境，或 enable/disable 覆盖、丢弃或静默重写非 auth 内容，G1 的 fail-closed 启动门只能阻止 direct ingress，并不能恢复已被修改的 runtime state；D3 所需的既有 provider 配置也可能已不可恢复。这违反任务验收中的状态保全要求，并使 rollback 的可恢复性不可验证。

最小修复：把目标 release 的 command 契约作为 G0 之前的显式 release gate，而非实现假设。该 gate 至少应声明并产出无敏感证据，证明：

- command 以与 service 相同的用户/环境/明确 config 位置读写；
- enable、check、disable 的幂等性、只读 check、缺失/畸形/冲突 auth 输入的拒绝行为；
- enable/disable 仅管理其拥有的 `[auth]` 字段，非 auth 配置及秘密引用在语义上保持不变；
- 该 release 的 source test/integration evidence、merge SHA 与目标 binary SHA 对应，并在 Azar 调用后以同一路径再次 `--check`。

这不要求在本部署任务中改 Const X 源码；它要求把 `constxd-auth-mini-native-sdk` 已交付的可核验证据设为部署前置条件。补齐后重跑本轮审查。

### Round 1 已闭环的设计项

- ACME ownership 已明确迁移为 `hosts/acorn/modules/constx.nix` 的唯一 declaration，并要求在 G2 验证 rendered vhost 与 ACME owner；不再依赖 `gatewayInstances.constx` 的隐式派生。
- G0（当前 gateway）、G1（目标 binary/auth 加当前 gateway ingress）和 G2（同一目标 release 的透明 base）现已清晰区分。G1 要求真实 active `ExecStart`、loopback 未认证 401、gateway active 和生效的 `auth_request`；补充的 `--specialisation` 证据足以支撑该切换机制的 CLI 可达性。
- G2 仅可在全部 G1 gate 通过后由普通 `switch` 进入，且要求验证 public/loopback 401、透明 vhost、无 `auth_request`/gateway redirect、ACME owner 与 service topology。
- D3 已扩展为 pair/connect/heartbeat/tool-result 四路径 canary，包含临时环境 revoke、机器凭据负例和“用户 JWT 不能替代机器凭据”。实际 Tool Call 明确依赖既有、已授权的 provider；条件不可取得时为 `INCONCLUSIVE/阻塞`，不得用连接或心跳替代。
- rollback 已固定为 G2 -> 同一 closure 的 G1 -> G0：在 disable 前必须验证 gateway hard gate，失败则停止并维持 auth enabled/fail-closed；G1 不允许 disabled config 重启，避免透明入口与 auth-disabled constxd 并存。

### 非阻塞说明

- D4 的真实浏览器登录仍是 production 验收门，而不是构建或配置检查的替代品。它已有 trigger、owner、方法、失败 rollback 和成功证据边界；在实际完成前不得宣称完整上线验收。
- `nixos-rebuild --help` 仅证明 specialisation 的 CLI 行为，不能替代未来的 Axiom build、Azar activation、G1/G2 rendered-config 与运行时 gate 证据；RFC 已把这些保留为后续验证，方向正确。

## 会话注意力摘要

- 阶段：review-rfc
- 阶段结论：FAIL
- 注意力等级：review
- 判断变化：round 1 的 ACME ownership、目标 binary 在 gateway 保护下的 G1、G2 direct cutover、四路径 Run Environment canary，以及 G2 -> G1 -> G0 fail-closed rollback 均已形成可执行设计；唯一仍未闭环的是目标 release `configure-auth` 对真实运行时状态的保全与可验证契约。
- 关键发现：
  1. F1：原子 writer 的名称不足以证明其读写 service 实际 config、保留非 auth runtime state，或使 disable 可恢复；这直接对应计划验收的状态保全要求。
  2. G1/G2 的 target-release、effective-ingress、401 与 ACME 验证门已解决 round 1 的 transient-open-window 设计缺口。
  3. D3 现要求既有授权 provider 下的真实 `tool-result`；条件缺失必须阻塞，不能由连接/心跳替代。
- 阻塞项：F1。修订 RFC 后必须重新执行 review-rfc；不得进入 engineer、merge 或 production rollout。
- 残余风险：D4 的真实浏览器 Auth Mini redirect 登录仍须在 G2 后由 deployment operator 完成；失败必须沿 G2 -> G1 -> G0 的既定路径 rollback。
- 人类动作：复核 RFC 作者补入目标 release command 的明确状态保全契约、无敏感 release evidence 及其 G0 前 gate；停止点为该修订重新通过独立 review-rfc。
- 自动下一步：回到 spec-rfc 补齐 F1 的 release gate 与验证映射，随后重跑 review-rfc；在新的 PASS 前不进入 engineer。
- 完整证据：
  - `.legion/tasks/constx-azar-native-auth-mini/plan.md:12-24,44-57`
  - `.legion/tasks/constx-azar-native-auth-mini/docs/research.md:14-22`
  - `.legion/tasks/constx-azar-native-auth-mini/docs/rfc.md:45-117`
  - `.legion/tasks/constx-azar-native-auth-mini/docs/review-rfc-round1.md:28-74`
