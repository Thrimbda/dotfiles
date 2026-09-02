# RFC：Azar 上 Const X 原生 Auth Mini 部署

> Profile: Heavy RFC
> Status: Draft
> Date: 2026-09-02

## Executive Summary

在原生 Auth Mini SDK release 合入后，`constx.0xc1.wang` 改为 Nginx TLS/透明反代到 loopback constxd；constxd 自己验证 Auth Mini issuer/JWKS/audience。默认 generation 移除 Const X 专用 gateway instance，但同一新 generation 保留一个 gateway staging specialisation，作为切换前 gate 和 fail-closed rollback recovery。Nix 不再解析 managed TOML；它只调用目标 constxd release 的原子 `configure-auth`/check 子命令。

## Context and Evidence

见 [research.md](research.md)。当前 gateway 路由是可用回滚面，但它不是目标架构。已有 Cybion vhost 是本机应用自验 Auth Mini JWT、Nginx 仅透明代理的现成 Acorn 模式。

## Goals

- 生产 Const X 使用应用原生 Auth Mini 验证，不使用 `auth-mini-gateway-constx`。
- 浏览器用户 API 和 Run Environment 机器 API 都在各自正确的认证边界内工作。
- 所有 Nix build 在 Axiom；Azar 只接收构建产物和 activate。

## Non-goals

- 不升级 Auth Mini、修改其 SQLite/SMTP/用户、DNS record、Cloudflare secret 或其它 gateway instance。
- 不删除共享 `auth-mini-gateway-env` secret 或残留 gateway SQLite；只取消 constx instance 的声明。
- 不更改 Axiom peer SSH tunnel、paired environment credential 或 Tool Call 协议。

## Options

### A. 继续 gateway + 精确机器端 bypass

当前工作方式。

- 优点：无需 release/config 改动。
- 缺点：重复认证边界且不符合目标。
- 结论：拒绝。

### B. 透明 Nginx + 直接编辑完整 managed TOML

将全量 `constxd.toml` 写入 Nix store。

- 优点：实现很短。
- 缺点：覆盖应用管理的 portable Pi 与用户 runtime setting；不接受。
- 结论：拒绝。

### C. 原子 constxd config command + gateway staging specialisation

目标 constxd release 自己管理 `[auth]`；NixOS base system 使用 direct ingress，同一 closure 的 staging specialisation 保留 gateway ingress。

- 优点：不以 shell 猜测 TOML；可以证明目标 binary 已在 gateway 保护下运行并拒绝未认证 API；rollback 有已验证的中间状态。
- 缺点：需要两个明确的 NixOS activation state。
- 结论：选择。

## Decision

### Nginx ownership

将 `constx.0xc1.wang` 的 Cloudflare DNS-01 ACME host declaration 移到 `hosts/acorn/modules/constx.nix`，使它不再随 `gatewayInstances` 派生/消失。默认 base system 从 `gatewayInstances` 移除 `constx`，因此不生成 `auth-mini-gateway-constx`；在 `constx.nix` 添加独立 vhost：

- `onlySSL = true`、复用现有 Cloudflare DNS-01 certificate；
- `/` 透明 `proxyPass = http://127.0.0.1:3210`；
- 保留流式 HTTP 所需的 HTTP/1.1、Host/X-Forwarded headers、Cookie、Authorization、无 buffering、长 read timeout 与 22 MiB request body；
- 不配置 `auth_request`、gateway login redirect、Cookie 清除，或 Run Environment 特殊 location。

所有公开 HTTP 流量都必须先经 constxd，因为 constxd 仍只监听 loopback。constxd middleware 负责用户 token 与机器 token 的分流。

### Managed auth config

目标 release 提供：

```text
constxd configure-auth --issuer https://auth.0xc1.wang --audience constx.0xc1.wang
constxd configure-auth --check --issuer https://auth.0xc1.wang --audience constx.0xc1.wang
constxd configure-auth --disable
```

enable/disable 由 constxd 的 Config/TOML 原子 writer 实现；check 不写文件。Nix service pre-start 在 G1/G2 只运行 check，配置缺失、issuer/audience 不匹配或目标 binary 不支持 command 时 service 不启动，direct ingress 因而返回失败而不是开放 API。Nix 不使用 `awk`、`sed`、固定完整 TOML 或对 private config 的文本 parse。

### Config state preservation release gate

在任何 G0 config mutation 前，目标 Const X release 必须提供下列无敏感 release evidence；没有它不允许执行 `configure-auth`、G1 或 G2：

Const X PR #82 已 squash merge 为最终 source SHA `92112facdb30a1a3a02e0a31fadcf3ff4a6ea379`。本 RFC 已用 `git show origin/master:.legion/tasks/constxd-auth-mini-native-sdk/docs/test-report.md` 验证该 merge SHA 包含 C1-C3 test report；任何与此 SHA 不匹配的 checkout、binary 或 config command 都不得执行 G0 mutation。

1. source merge SHA、对应 binary SHA-256、Axiom build log 与 source `configure-auth` test locator 相互对应；
2. command 在与 `constxd.service` 完全相同的 user/HOME/XDG environment 下定位 config；
3. clean config 的 enable bootstrap、重复 enable/check/disable、disabled no-op 与 check no-write；
4. 畸形 config、legacy issuer-only auth、冲突 mode/argument、不合法 issuer/audience 全部 non-zero/no-write；
5. 对已有有效 config，除 `[auth]` 外的 non-auth state 语义保全：server/database/execution、Pi provider/model/thinking、paths 与 constxd-owned non-auth setting 保持一致；SQLite settings、secret value 和 provider credential 不被 command 打开或写入；
6. Azar 上实际执行 enable 后，以同一 target binary 和同一 service environment 运行 `configure-auth --check`，只记录 exit/status/owner/mode，不导出 config 内容。

此 gate 把“原子 writer”转化为可审计行为契约；其 source tests 是部署的硬依赖，Azar runtime check 只确认目标环境确实满足同一契约，不代替 source evidence。

### Final source evidence compare-or-rerun

G0 的 source evidence baseline 是 PR #82 merge 前 head `699bfc8fac35c048c7f11965f7902e99ba970dc2`；final object 是 `92112facdb30a1a3a02e0a31fadcf3ff4a6ea379`。Axiom 必须生成 `source-evidence-compare.txt`，逐项记录 baseline/final blob id 和 `git diff --quiet` 结果，比较范围严格为：

| Path | Baseline blob | Final blob |
| --- | --- | --- |
| `crates/constxd/src/config.rs` | `5d94875758e84ec32e966f500b56e326bc9a1277` | `5d94875758e84ec32e966f500b56e326bc9a1277` |
| `crates/constxd/src/main.rs` | `bd9d467b157193507a8b9fcb8c18f8980a982b07` | `bd9d467b157193507a8b9fcb8c18f8980a982b07` |
| `crates/constxd/tests/bootstrap_process.rs` | `2f83ed040df3d91be9ad71589e2e1cf1315d2e17` | `2f83ed040df3d91be9ad71589e2e1cf1315d2e17` |
| `.legion/tasks/constxd-auth-mini-native-sdk/docs/test-report.md` | `6500f3f394f3cd262a2e10d6144780e9e8b6584e` | `6500f3f394f3cd262a2e10d6144780e9e8b6584e` |
| `.legion/tasks/constxd-auth-mini-native-sdk/docs/evidence/cargo-test-parallel-retry.txt` | `01e57ffe6126ae5bcfc94fab805e806dd8613eb9` | `01e57ffe6126ae5bcfc94fab805e806dd8613eb9` |
| `.legion/tasks/constxd-auth-mini-native-sdk/docs/evidence/cargo-test-serial.txt` | `8aa3e1da2cb861300824f5cb66fb6b7b152640b0` | `8aa3e1da2cb861300824f5cb66fb6b7b152640b0` |

只有全部 baseline object 可读、final blob 等于表中值、这组 paths 的 `git diff --quiet` 为 0，且完整 checkout 的 `git diff --quiet 699bfc8fac35c048c7f11965f7902e99ba970dc2 92112facdb30a1a3a02e0a31fadcf3ff4a6ea379` 也为 0，才允许标记 `source_evidence_mode=reused` 并复用 merged task evidence。任何 candidate ref/对象不可读、任一 blob 或 diff 不匹配、或比较输出无法保存，均必须从 final clean checkout 运行 `cargo test -p constxd -- --test-threads=1`、`cargo clippy -p constxd --all-targets -- -D warnings`、`cargo fmt --all -- --check`、`npm run build`、`npm run test:auth-mini` 和 `npm run test:auth-gate-browser`，把脱敏 raw output、exit status、final SHA 写入 `source-evidence-rerun.txt`；任一失败停止于 G0。

### Final merge to target-binary provenance

G0 mutation 前必须生成并保存一个无敏感 release manifest，字段为 `source_merge_sha`、`source_evidence_mode`、`source_evidence_record`、`binary_sha256`、`axiom_build_host`、`azar_release_binary`、`azar_release_binary_canonical`、`built_at`。执行顺序和负路径如下：

1. Axiom 上用于 release 的 Const X checkout 必须 clean，且 `git rev-parse HEAD` 精确等于 `92112facdb30a1a3a02e0a31fadcf3ff4a6ea379`；不等即停止。
2. Axiom 从该 checkout 构建 binary，计算 SHA-256，并将 binary 与 manifest 一起复制到 Azar 的 release directory。
3. Azar 上必须使用同一 manifest 重新计算 target binary SHA-256；不匹配即停止，且不得调用 `configure-auth`。
4. G0 只允许以该明确 `azar_release_binary` 路径调用 `configure-auth`。G1 activate 后必须记录 `g1-executable-binding.txt`：effective systemd `ExecStart` 的 executable path、`MainPID`、`readlink -f /proc/$MainPID/exe`、以及该 executable 的 SHA-256。unit path、PID canonical executable、manifest canonical path 和两个 SHA-256 必须全部相等；任一 resolver/PID/path/hash/unit-state 不可读或不一致都保持或回到 G0 gateway，不进入 G2。

最终 source locators（已在 merge SHA 下验证）：

- `constx/.legion/tasks/constxd-auth-mini-native-sdk/docs/test-report.md`
- `constx/.legion/tasks/constxd-auth-mini-native-sdk/docs/evidence/cargo-test-parallel-retry.txt`
- `constx/.legion/tasks/constxd-auth-mini-native-sdk/docs/evidence/cargo-test-serial.txt`
- `constx/.legion/tasks/constxd-auth-mini-native-sdk/docs/evidence/auth-gate-browser.txt`
- `constx/.legion/tasks/constxd-auth-mini-native-sdk/docs/evidence/auth-mini.txt`

### G0 / G1 / G2 state machine

| State | constxd binary / auth | Nginx ingress | 可进入下一步的 gate |
| --- | --- | --- | --- |
| G0 | 当前 release，auth disabled | current gateway | 当前生产状态 |
| G1 `constx-native-auth-staging` | 目标 release，auth enabled + check | 当前 constx gateway + existing machine exceptions | source evidence compare/rerun PASS；active ExecStart path、MainPID executable canonical path 和 SHA-256 全部匹配 release manifest；loopback user API 无凭据为 401；gateway unit active；有效 Nginx config 对用户 upstream 含 `auth_request` |
| G2 base | 同一目标 release，auth enabled + check | transparent direct constx vhost | 仅在全部 G1 gate 通过后进入；正常目标状态 |

NixOS `specialisation.constx-native-auth-staging` 仅覆盖 ingress mode；它保留目标 release、service check、ACME host 和其它主机服务。base G2 是唯一“不生成 `auth-mini-gateway-constx`”的默认运行状态。

### Ordered rollout

1. 从 final source SHA `92112facdb30a1a3a02e0a31fadcf3ff4a6ea379` 在 Axiom 比较 final source evidence 或按规定重跑 C3，然后构建 release binary；先满足 Config state preservation release gate 和 Final merge to target-binary provenance，记录 release manifest、target release directory 与前端 native SDK bundle proof。
2. 在 Axiom 构建同时含 G1 specialisation 和 G2 base 的 Acorn closure，复制 closure/binary 到 Azar；此时仍是 G0。
3. 在 G0 gateway 仍保护公网时，以目标 binary、与 service 相同的 user/HOME/XDG environment 执行 `configure-auth --issuer ... --audience ...`，随后运行同一 binary 的 `--check`；不得重启旧 service。旧 service 若意外重启而不认识 `audience` 会 fail-closed。
4. 从 Axiom 使用 `nixos-rebuild switch --specialisation constx-native-auth-staging --build-host localhost --target-host ... --ask-sudo-password --sudo` 激活 G1。必须生成并通过 g1-executable-binding record 和 G1 table 全部 gate；任一失败停止，不得进入 G2。
5. 仅在 G1 全部通过后，以同一 Axiom-only build path 运行无 `--specialisation` 的 switch 进入 G2。验证 rendered vhost/ACME owner、active services、public/loopback unauthenticated user API 401、且无 `auth_request` 或 gateway redirect。
6. 验证完整 Run Environment matrix 和真实浏览器 Auth Mini redirect 登录、App API/SSE。

## Verification

| Claim | 预注册 | 正向与反例 | 阻塞 |
| --- | --- | --- | --- |
| D1 | objective / now / routine；ingress auth boundary；critical；risk: open user API、错误 binary、ACME ownership 丢失或 config state 损坏；owner: verify-change | Config state preservation release gate；G1 target ExecStart/binary hash/auth check/loopback 401/gateway `auth_request` gate；G2 rendered Nginx + ACME host + HTTP：`/api/auth/config` enabled，未认证 user API 401，Nginx 无 `auth_request`/gateway redirect；有效登录后 UI/API。 | block-merge |
| D2 | objective / now / routine；service topology；high；risk: collateral service outage；owner: verify-change | G2 `auth-mini-gateway-constx` absent；G1 staging gateway active；auth-mini、其它 gateway instances、Nginx healthy。 | block-merge |
| D3 | objective / now / routine；machine protocol；critical；risk: remote execution outage；owner: verify-change | 不记录 token 的 matrix：新临时 Run Environment 一次性 pairing 成功；既有 Local Mac/Axiom connect + heartbeat；在已存在、已授权的模型/provider 配置下，受控 temporary workspace 的实际 Tool Call 收到对应 tool-result；pair/connect/heartbeat/tool-result 的缺失或过期机器凭据拒绝，用户 JWT 不能替代机器凭据；完成后 revoke 临时环境。若无法取得该既有 provider 条件，D3 为 INCONCLUSIVE/阻塞，不以 connection 代替。 | block-merge |
| D4 | objective / deferred / routine；真实浏览器登录；critical；risk: production user lockout；owner: deployment operator | 触发：新 generation 可用。方法：从 `https://constx.0xc1.wang` 跳转 Auth Mini、登录、回调、API/SSE。失败：立即执行 rollback；成功：记录无敏感 status evidence。 | defer-by-contract |

D4 在真实浏览器完成前不能声称完整生产验收；其 deferred protocol 是 rollout 的人类验证步骤，而非自动通过。

## Rollback

如果 D1-D3 失败、native SDK 不能加载，或 D4 登录失败：

1. 从 G2 回切同一 closure 的 G1 `constx-native-auth-staging`，而不是直接回旧 generation。G1 使用目标 binary，故能读取新的 `audience` config。
2. 在任何 disable 前验证 G1 table 的 gateway hard gate：`auth-mini-gateway-constx` active、active Nginx config 对 constx user upstream 含 `auth_request`、Nginx 不再是 transparent vhost、无凭据请求不能直达 constxd。任一 gate 失败立即停止 rollback，保持 auth enabled/fail-closed。
3. 停止 constxd，以目标 binary 执行 `configure-auth --disable`；不得在 G1 重启 constxd，因为 G1 pre-start 的 check 会拒绝 disabled config。
4. 只有 disable 成功且 config 已无 auth section 后，才从 Axiom switch 回 G0/旧 generation，使旧 binary 启动；确认 `/api/auth/config` disabled、gateway user entry 和其它 services healthy。

不删除 database、gateway SQLite、paired environment state 或任何 agenix secret。该顺序把可用性短暂中断限定在可验证的 gateway 保护状态，避免“constxd disabled 但 transparent Nginx 仍在”的未认证公开窗口。

## Observability and Privacy

- 只记录 source SHA、binary SHA、Nix generation、HTTP code、unit active/inactive、环境 availability。
- 禁止记录 token、cookie、email、OTP、pairing URL fragment、密码、完整 TOML 或 age 解密内容。
- 与实际用户交互的登录证据只记录成功/失败、时间和不含身份的 route/status。

## Open Questions

无设计阻塞。D4 是明确的生产验证门；G1/G2 是 D1-D3 的 activation gate，不得用成功构建替代。
