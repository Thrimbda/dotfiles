# 变更审查：Azar 原生 Auth Mini 与 auto-redirect release uplift

审查身份：`reviewer-calm-gecko`（独立 dotfiles reviewer）。

审查范围：只读检查 `plan.md`、`log.md`、`docs/rfc.md`、全部 `docs/review-rfc*.md`、`docs/test-report.md`、`docs/evidence/*`，以及 `hosts/acorn/default.nix`、`hosts/acorn/modules/constx.nix`、`hosts/acorn/modules/auth-mini.nix` 从 `4a1e1ece` 到 `HEAD` 的实际 diff。未修改生产代码、`plan.md`、`tasks.md` 或 `log.md`；本文件是唯一新增产物。

## Verdict

FAIL

## 范围与静态实现结论

实现本身与已通过的 RFC 设计一致，且没有越出任务范围。

- Base 默认 `nativeAuthIngress = "direct"`，只由 `constx.nix` 生成 `constx.0xc1.wang` 的 loopback `proxyPass`；其 location 没有 `auth_request`、gateway redirect 或 Run Environment path bypass。staging specialisation 才覆盖为 `gateway`，并由 `auth-mini.nix` 条件生成 `auth-mini-gateway-constx` 与其 `auth_request` vhost。
- `constx.0xc1.wang` 的 ACME host 由 `constx.nix` 单独声明；`auth-mini.nix` 无论 base 或 staging 都从 gateway-derived ACME 列表排除 `constx`。静态所有权为单一、没有重复或随 gateway 消失的路径。
- 目标 pin 正确为 `059eab4d6a8eac156333f9357838d8ab9acc203c`；在 `/Users/c1/Work/constx` 中该 Git object 可读，且为 PR #83 的 redirect 修复提交。`constxd.service` 和只读 `configure-auth --check` 都引用该 pin。

上述静态结论不能替代 Azar 的实际 systemd、Nginx、ACME 或构建 provenance。

## 重新聚合的 claims 与证据充分性

| Claim / gate | 独立状态 | 结论 |
| --- | --- | --- |
| D1：G2 direct ingress、应用 auth 和未认证 API 401 | INCONCLUSIVE | Nix 代码与 `nix-eval-059eab4.txt` 支持 base direct / staging gateway 的配置形状；`azar-runtime-059eab4.txt` 也声明 config check、401 和无 `auth_request`。但该文件只有结论字段，没有实际 `systemctl show`、`MainPID` 值、`readlink /proc/$PID/exe`、`sha256sum`、`configure-auth --check`、Nginx effective config 或 HTTP 请求/响应的原始输出，无法独立重建「命令/实际进程/结果 -> D1」。 |
| D2：constx gateway 被移除且其余拓扑健康 | INCONCLUSIVE | 静态 base/staging 条件化生成正确，摘要亦写有 `auth-mini-gateway-constx=inactive` 与其它实例 active；但缺 `systemctl`/rendered Nginx 的原始输出，不能审计实际 unit topology。 |
| G1 是 G2 的前置 gate | INCONCLUSIVE | RFC 要求 G1 的 release manifest、source compare-or-rerun record，以及 `g1-executable-binding.txt`（effective `ExecStart`、MainPID、canonical executable、SHA）全部通过后才进入 G2。当前 evidence 目录没有这三类记录，也没有 G1 activation/gateway `auth_request` 的运行时输出；不能证明本次 G2 switch 消费过 G1 gate。 |
| ACME ownership | PASS（静态）/ INCONCLUSIVE（运行时） | 代码已形成单一声明所有权；但现有 Nix eval 和 runtime evidence 未输出 rendered ACME host/certificate owner，无法把静态声明提升为本次 Azar activation 的运行时事实。 |
| Axiom-only build / Azar switch / `059eab4` binary chain | INCONCLUSIVE | 文件分别声称 Axiom build、Axiom `nixos-rebuild` 与 Azar switch，且 binary SHA 在摘要中一致；但没有 release manifest、source evidence compare/rerun output、Axiom checkout identity、Azar stage hash 复算原始输出或实际 switch 输出。声明本身不足以把 source SHA、构建 binary、Azar 文件与运行 MainPID 绑定。 |
| D3：Run Environment machine protocol | DEFERRED（用户） | 仅有本机/Axiom service active；没有 pairing、connect、heartbeat、tool-result 或凭据负例。按用户明确决定保持 DEFERRED，绝不写作 E2E PASS。 |
| D4：production browser/passkey/auth redirect | DEFERRED（用户） | 没有浏览器/Passkey 会话证据。按用户明确决定保持 DEFERRED，绝不写作 production E2E PASS。 |

## Blockers

### B1：运行时 provenance 不能支持 test-report 对 D1/D2 的 PASS

`docs/test-report.md` 将 D1/D2 记为 PASS，并称存在实际 `MainPID` executable、manifest、SHA、config check、401 和 gateway topology；但被引用的四个 evidence 文件只含人工汇总键值。特别是 `azar-runtime-059eab4.txt` 不含 PID、effective `ExecStart` 的来源、canonical path 的命令输出或 manifest locator；evidence 目录也不存在 RFC 指定的 release manifest、`source-evidence-compare.txt`/`source-evidence-rerun.txt` 和 `g1-executable-binding.txt`。

影响：无法独立验证实际运行的 binary 是否为 `059eab4` 构建物，无法证明 G1 在 G2 前实际通过，也不能将 401/config check/Nginx topology 从自述提升为可审计的 block-merge 证据。依照认知验证协议，缺少执行记录、原始输出 locator 与 claim 映射时，相关 claim 只能是 INCONCLUSIVE。

最小补证方向：保留脱敏原始输出并逐项映射 D1/D2：Axiom checkout/source comparison 或 rerun、release manifest、Azar stage SHA 复算、G1 activation 的 effective `ExecStart` + `MainPID` + `/proc/$PID/exe` + SHA、G1 gateway `auth_request`、G2 effective Nginx/ACME owner、config check，以及 loopback/direct/public 401 的命令和响应状态。补证必须说明 G1 成功后才执行 G2；不得以新摘要替代这些 records。

### B2：D3/D4 的用户 deferred 不得被 production state 误解为通过

现有报告正确没有把 service active 解释为 Run Environment E2E，也没有把 home/API HTTP 状态解释为浏览器/Passkey 登录；这两项必须保持用户 DEFERRED。它们不是 B1 的替代证据，也不应在补 B1 时被改写为 PASS。后续若用户执行观察，应按预注册的 machine matrix 与浏览器流程保存无敏感结果，并更新结论；失败时停止进一步 rollout 并按 RFC rollback 路径处理。

## 安全视角

适用。变更跨越 Nginx authentication boundary、JWT audience verifier、机器 token 路由与 production ingress。静态配置不存在 base `auth_request` 残留或明示 open proxy；但认证边界的关键运行时事实目前只有摘要，故不能批准 `test-report` 的 deployment PASS 或进入 merge/完成状态。

## 可选建议

- 证据文件可保留当前便于阅读的摘要，但每条摘要应链接同目录的脱敏原始 command/output record；不要记录 token、cookie、pairing URL、完整 TOML 或任何 secret。
- 运行时 ACME 证据只需证明 owner/host 与有效 Nginx 引用，不需要导出证书私钥或 Cloudflare 凭据。

## 会话注意力摘要

- 阶段：review-change
- 阶段结论：FAIL
- 注意力等级：review
- 判断变化：静态 diff 确认 base G2 direct/no `auth_request`、staging G1 gateway、单一 ACME ownership 与 `059eab4` pin 均符合 contract；但 verify-change 把所需运行时 provenance 压缩为无 PID/命令/原始输出的摘要，不能独立重算 D1/D2 或确认 G1 曾作为 G2 前置 gate。
- 关键发现：
  1. B1（block-merge）：缺 release manifest、source compare/rerun、G1 executable binding，以及 actual ExecStart/MainPID/SHA/config-check/401/gateway topology 的可审计原始记录，D1/D2 只能为 INCONCLUSIVE。
  2. ACME ownership 与 ingress state machine 的 Nix 代码正确；这不证明本次 Azar activation 的 rendered/effective configuration。
  3. D3/D4 按用户决定均保持 DEFERRED；service active、public home 200 或 unauthenticated 401 均不是 machine E2E 或 browser/passkey PASS。
- 阻塞项：B1。当前 `docs/test-report.md` 的 D1/D2 PASS 与其所列 evidence 不可由独立 reviewer 重算。
- 残余风险：认证边界、实际运行 binary 和 G1 -> G2 顺序未被可审计地绑定；D3/D4 的生产观察仍未执行且不得宣称通过。
- 人类动作：复核补充后的脱敏 provenance bundle 是否逐项覆盖 B1，并在 D3/D4 仍为 DEFERRED 的前提下决定是否解除 merge 门。
- 自动下一步：退回 verify-change 补 B1 指定的 records 后重跑独立 review-change；停止点为本审查获得 PASS 前不得 merge、cleanup 或宣称 production E2E PASS。
- 完整证据：
  - `hosts/acorn/default.nix:49-56`
  - `hosts/acorn/modules/constx.nix:6-20,31-58,76-107`
  - `hosts/acorn/modules/auth-mini.nix:13-65,215-220`
  - `docs/rfc.md:93-115,125-162`
  - `docs/test-report.md:9-49`
  - `docs/evidence/axiom-build-059eab4.txt:1-12`
  - `docs/evidence/azar-runtime-059eab4.txt:1-18`
  - `docs/evidence/nix-eval-059eab4.txt:1-9`
  - `docs/evidence/public-and-peer-059eab4.txt:1-6`
