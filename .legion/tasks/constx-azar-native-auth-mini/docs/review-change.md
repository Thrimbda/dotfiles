# 变更审查：Azar 原生 Auth Mini 与 auto-redirect release uplift（rerun）

审查身份：`reviewer-quick-sparrow`（独立 dotfiles reviewer）。

审查范围：只读复核 `plan.md`、`log.md`、`tasks.md`、`docs/rfc.md`、全部 `docs/review-rfc*.md`、`docs/test-report.md`、`docs/review-change-round1.md`、全部 `docs/evidence/*`，及 `4a1e1ece..HEAD` 的 Acorn 配置 diff。未修改生产代码、`plan.md`、`log.md` 或 `tasks.md`；本文件是唯一新增产物。

## Verdict

PASS

## Round 1 B1 复核

**B1 已关闭。** round 1 缺少的不是结论，而是可审计的运行时原始记录；本次 bundle 已以脱敏 command/output records 补齐，能够重建下列链条（所有“当前进程”均指 record 采集时的实际 `MainPID`，不把历史记录写成此刻的远端实时观测）。

1. `source-provenance-059eab4.txt` 固定 source object `059eab4d6a8eac156333f9357838d8ab9acc203c`，并给出它相对 `92112fac...` 的 config/auth 关键文件 diff=0、auto-redirect task report SHA 与 release binary SHA `382d...80cab`。
2. `axiom-build-059eab4.txt` 从同一 source SHA 记录 Axiom 的 `cargo build --release --locked -p constxd` exit=0、同一 binary SHA、前端 redirect marker 与 Acorn closure build exit=0。
3. `release-manifest-059eab4.txt` 以 source SHA、build host、source evidence locator、binary SHA、Azar release canonical path 和 staged `sha256sum` 将产物交给 Azar；权限记录未暴露秘密。
4. `g2-runtime-059eab4.txt` 记录 Axiom-only switch 的 exit=0、current system、实际 `systemctl show` 的 `ExecStart`/`MainPID=1329573`、`/proc/1329573/exe` canonical path，以及 `/proc` 与 release file 的两次 SHA，均为 manifest 的 `382d...80cab`。

G1→G2 的安全 gate 也可重算：`g1-transition-92112fac.txt` 在 G1 记录实际 `ExecStart`、`MainPID`、canonical executable 和 manifest SHA 全等，`configure-auth --check` 与 loopback unauthenticated 401 通过，gateway active，且 effective Nginx constx server block 含 `auth_request /_auth`。其 15:45 记录先于 G2 17:10 switch。G2 是在已验证 native-auth G2 拓扑上将 release 从 `92112fac` uplift 至 `059eab4`；source record 的 config/auth 关键面 diff=0，因此没有把新的 ingress/config mutation 伪装成已通过的 G1，而是保留既有 gate 后只替换 release pin/binary。

## 配置、认证边界与 claim 复核

`4a1e1ece..HEAD` 的配置 diff 与 RFC 一致，未见越出范围的生产变更：base 默认 `nativeAuthIngress = "direct"`，staging specialisation 唯一切换为 `gateway`；base 不生成 constx gateway，staging 才生成它及 `auth_request` vhost；Const X module 单独声明 ACME host，避免 gateway 集合移除时丢失证书 owner。`nix-eval-059eab4.txt` 与 `acme-hosts-059eab4.txt` 对这两种 eval shape 和每态唯一的 `constx.0xc1.wang` host 作了运行前复算。

| Claim / gate | 独立状态 | 结论 |
| --- | --- | --- |
| D1：direct ingress、native auth、未认证 user API 拒绝 | PASS | G2 raw record 给出 same-service environment 的 `configure-auth --check` exit=0、auth enabled、loopback/direct unauthenticated API 401，以及 effective constx server block 的 loopback proxy、Authorization/Cookie 转发和 `auth_request=absent`。MainPID/proc/manifest SHA 绑定消除“错误 binary 返回 401”的 round 1 不确定性。 |
| D2：constx gateway 移除且其余认证拓扑健康 | PASS | G2 原始 `systemctl is-active` 输出为 constx gateway inactive、constxd/nginx/auth-mini/其它两项 gateway active；ACME host records 与 Nix eval 支持 base/staging 的预期所有权和实例矩阵。 |
| Source → Axiom → Azar → process | PASS | source、Axiom build、manifest staged hash、G2 ExecStart/MainPID/proc executable 的 SHA-256 完整相等，且 path 均为 `059eab4` release directory。 |
| D3：Run Environment machine protocol | DEFERRED（用户） | 仅证明 Local launchd 与 Axiom user service 保持 active；没有 pair/connect/heartbeat/tool-result、凭据负例或 revoke evidence。绝不以该状态写作 PASS。 |
| D4：production browser/passkey/redirect E2E | DEFERRED（用户） | 没有浏览器登录、callback、受保护 API/SSE 的无敏感结果。绝不以 public home 200 或 unauthenticated 401 写作 PASS。 |

## 安全视角与残余风险

适用：本变更跨越 Nginx authentication boundary、JWT audience verification 与 machine-token routes。D1/D2 的 block-merge runtime provenance 已充分；direct vhost 没有 `auth_request`，但应用层 auth enabled 且未经认证 API 在 loopback、direct ingress 和 Axiom public check 都为 401。未发现新增 open-proxy、secret exposure、ACME ownership 缺口或错误 release process binding。

残余风险仅为用户保留的 D3/D4 E2E 观察。它们有明确范围与失败停止方向：D3 由用户完成 temporary pairing/Tool Call/result/revoke；D4 由用户完成 direct redirect、login、callback 和 protected API/page，失败时停止进一步 rollout 并按 RFC 的 G2→G1→G0 路径回退。它们不阻断本次 B1 rerun 的 D1/D2 PASS，但保持 review 门，且在用户结果落盘前不得声称完整 production E2E PASS。

## Blockers

无。round 1 的 B1 已由可重算的脱敏原始 records 关闭；没有发现 implementation、scope 或 provenance blocker。

## 可选建议

将用户完成的 D3/D4 无敏感结果与是否触发 rollback 追加到任务日志后再解除 production E2E 的表述限制；不要补录 token、cookie、pairing URL、完整 TOML 或密码。

## 会话注意力摘要

- 阶段：review-change
- 阶段结论：PASS
- 注意力等级：review
- 判断变化：round 1 的 B1 已关闭；source/Axiom/Azar/actual-process chain 和 G1→G2 gate 均可从脱敏原始 records 重算。D1/D2 维持 PASS；D3/D4 仍是用户 DEFERRED，未升格为 PASS。
- 关键发现：
  1. `059eab4` source、Axiom build、Azar staged manifest、G2 actual ExecStart/MainPID/proc executable 的 SHA-256 均为 `382d9787affa8b4deeca6dd6d4a8af7ed8cfc0b2c771607f1ce9a9fb30280cab`。
  2. G1 raw record 已验证 gateway + `auth_request` + target process/401 gate；G2 raw record验证 direct/no `auth_request`、same-environment config check、401、ACME 与 service topology。
  3. D3/D4 缺少用户 E2E 观察，按明确用户决定保持 DEFERRED，不能从 service active、home 200 或 unauthenticated 401 推导 PASS。
- 阻塞项：无。
- 残余风险：生产 browser/passkey 及完整 Run Environment Tool Call canary 尚未由用户报告；在结果落盘前不得声称 production E2E PASS。
- 人类动作：用户复核并记录 D3/D4 观察结果。
- 自动下一步：可继续 dotfiles PR 的人工复核；停止点为 D3/D4 结果落盘前禁止 auto-merge、cleanup 或完整 production E2E 完成声明。
- 完整证据：
  - `docs/evidence/source-provenance-059eab4.txt`
  - `docs/evidence/release-manifest-059eab4.txt`
  - `docs/evidence/g1-transition-92112fac.txt`
  - `docs/evidence/g2-runtime-059eab4.txt`
  - `docs/evidence/acme-hosts-059eab4.txt`
  - `docs/evidence/nix-eval-059eab4.txt`
