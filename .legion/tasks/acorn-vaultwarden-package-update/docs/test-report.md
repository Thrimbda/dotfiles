# Verification Report: Acorn Vaultwarden Package Update

## Scope and Method

This report verifies the isolated Vaultwarden input, package compatibility, version selection, official release compatibility, immediate backup preflight, and the required Axiom-to-Acorn deployment path. It does not inspect secrets, database contents, environment-file values, or user vault data.

Direct Nix evaluation, Git lock comparison, systemd output, and the official Vaultwarden GitHub Releases API are the lowest-cost methods sufficient for the registered claims. The required full deployment was attempted only with the prescribed `nixos-rebuild switch` command from Axiom.

## Claim Register

| Claim | Status | Evidence | Independence and Confidence | Residual Uncertainty |
|---|---|---|---|---|
| `lock-isolation` | PASS | `docs/evidence/lock-and-eval.txt` | Git diff and lock-node comparison are direct, high independence, high confidence | None within the checked lock file. |
| `package-compatibility` | PASS | `docs/evidence/lock-and-eval.txt` | Acorn NixOS configuration evaluated its service, Web Vault, and `ExecStart` paths directly; high independence, high confidence | Full closure build was subsequently blocked by an unrelated dependency. |
| `fresh-package` | PASS | `docs/evidence/lock-and-eval.txt` | Dedicated input is locked to `0954f7ee2f6b` and evaluates Vaultwarden `1.37.0`; high confidence | “Latest” is the selected `nixos-unstable` package at lock-update time, not an unpinned upstream commit. |
| `release-compatibility` | PASS | `docs/evidence/release-1.37.0.txt` | Official upstream GitHub release API covers `1.36.0...1.37.0`; medium-high confidence | Release notes cannot prove runtime migration behavior for this data set. |
| `backup-preflight` | PASS | `docs/evidence/preflight-and-build.txt` | Direct Acorn systemd and directory metadata output; high confidence | The eventual switch did not occur because the local build failed. |
| `post-switch-health` | INCONCLUSIVE | `docs/evidence/preflight-and-build.txt` | Not runnable: local Axiom system build failed before transfer or activation | Core acceptance cannot pass without a successful switch and post-switch checks. |
| `restore-fidelity` | DEFERRED | `docs/rfc.md` | Deferred protocol is complete; no destructive production restore run | Must be exercised by `acorn-vaultwarden-restore-drill`. |

## Execution Record

- `git diff --check` exited 0.
- `git diff -- flake.lock` shows only the new `nixpkgs-vaultwarden` node and root reference; the existing `nixpkgs` and `nixpkgs-unstable` revisions remain unchanged.
- Acorn configuration evaluation resolved Vaultwarden `1.37.0`, Web Vault `2026.6.4+0`, and an `ExecStart` path ending in `vaultwarden-1.37.0/bin/vaultwarden`.
- The official `1.37.0` release is immutable, published 2026-07-24, and compares directly from `1.36.0`. Its notes report security fixes and client compatibility but no manual migration requirement for this interval.
- The immediate `backup-vaultwarden.service` run succeeded at 13:08:25 CST, with the existing backup directory present and the timer still loaded.
- The exact prescribed `nixos-rebuild switch` began building on Axiom but failed at the pre-existing `auth-mini` fixed-output hash mismatch. No Acorn-local build, closure-transfer retry, or activation retry was attempted.

## Domain Verifier and Provenance

No separate domain verifier applies. All non-deferred claims use routine Nix, Git, systemd, and HTTPS evidence. Commands and sanitized raw outputs are located in the three evidence files listed above. No verifier or tool changed the pre-registered criticality or blocking policy.

## Authority Evidence

`release-compatibility` uses the official `dani-garcia/vaultwarden` GitHub Releases API record for tag `1.37.0`, retrieved over HTTPS. The record identifies the canonical HTML release URL, immutable tag, publication timestamp, and full changelog range from `1.36.0`. The relevant raw fields and conclusion are preserved in `docs/evidence/release-1.37.0.txt`; no third-party summary was used.

## Deferred Claim

`restore-fidelity` remains DEFERRED under the RFC protocol: an Acorn operator must execute the isolated restore drill within 90 days or at the first backup, rollback, or storage anomaly. Its stop condition, required data, successor task, and pass/fail dispositions are in `docs/rfc.md`.

## Failure and Stop Condition

The required deployment failed on Axiom because the existing `auth-mini` fixed-output derivation downloaded content with a SHA-256 different from its pin. This is outside the approved Vaultwarden scope. Per Acorn build safety, deployment stops here: do not retry with an Acorn build host and do not alter or bypass the hash without a separately approved scope.

## Attempt 1 Verdict

FAIL

## Attempt 1 会话注意力摘要

- **阶段**: verify-change
- **阶段结论**: FAIL
- **注意力等级**: decide
- **判断变化**: 隔离输入、版本解析、发布兼容性和即时备份均通过；完整 Acorn 构建被无关 `auth-mini` 固定输出哈希失配阻断。
- **关键发现**: Vaultwarden 将从 `1.36.0` 变为 `1.37.0`；服务和 Web Vault 同源；未发生远程闭包传输或激活。
- **阻塞项**: `auth-mini` 的 SHA-256 pin 与上游 `latest` 下载内容不匹配，导致 Axiom 系统构建失败。
- **残余风险**: `post-switch-health` 未执行；`restore-fidelity` 仍为 deferred；不得以 Acorn 本地构建绕过该失败。
- **人类动作**: 选择是否显式扩大范围以修复 `auth-mini` 的固定输出哈希，或保持本次 Vaultwarden 更新阻塞。
- **自动下一步**: 等待人类决定；未获范围授权前不重试构建、部署或激活。
- **完整证据**: `.legion/tasks/acorn-vaultwarden-package-update/docs/test-report.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/preflight-and-build.txt`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/lock-and-eval.txt`

## Attempt 1 Handoff

结果: Acorn Vaultwarden Package Update · verify-change · FAIL · attention:decide
变化: 隔离输入和 `1.37.0` 包解析通过；即时备份成功；Axiom 构建被无关 auth-mini 哈希失配阻断
风险: 未切换，因此未获得 post-switch 健康证据；不得在 Acorn 本地构建
下一步: 等待用户决定是否授权单独或扩展范围修复 auth-mini pin，停止所有部署重试
证据: `.legion/tasks/acorn-vaultwarden-package-update/docs/test-report.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/preflight-and-build.txt`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/release-1.37.0.txt`

## Verification Attempt 2

The user authorized a narrowly reviewed auth-mini package-pin repair after Attempt 1. The repair changed only `packages/auth-mini/default.nix`: source reference, `curlOpts`, date metadata, and fixed-output hash. The required full Axiom build, transfer, activation, and post-switch checks all completed successfully.

## Updated Claim Status

| Claim | Status | Evidence | Independence and Confidence | Residual Uncertainty |
|---|---|---|---|---|
| `lock-isolation` | PASS | `docs/evidence/lock-and-eval.txt` | Git diff and lock-node comparison are direct; high confidence | None within the checked lock file. |
| `package-compatibility` | PASS | `docs/evidence/lock-and-eval.txt`, `docs/evidence/deployment-success.txt` | Configuration evaluation and complete Axiom closure build; high confidence | None beyond ordinary runtime behavior. |
| `fresh-package` | PASS | `docs/evidence/lock-and-eval.txt` | Dedicated Nixpkgs node resolves Vaultwarden `1.37.0`; high confidence | “Latest” remains the selected NixOS unstable package at lock-update time. |
| `release-compatibility` | PASS | `docs/evidence/release-1.37.0.txt` | Official upstream release API covers `1.36.0...1.37.0`; medium-high confidence | Release notes cannot prove data-specific migration behavior. |
| `auth-mini-asset-provenance` | PASS | `docs/evidence/auth-mini-asset.txt` | Official GitHub asset record, exact digest conversion, and actual Nix fetch/build agree; high confidence | Upstream binary is not independently code-audited in this task. |
| `auth-mini-fetch-compatibility` | PASS | `docs/evidence/deployment-success.txt` | Required full Axiom build fetched asset ID `488807338` and built the new derivation; high confidence | Future GitHub API or asset deletion will fail closed. |
| `backup-preflight` | PASS | `docs/evidence/deployment-success.txt` | Direct Acorn systemd and directory metadata output; high confidence | No destructive restore was performed. |
| `post-switch-health` | PASS | `docs/evidence/deployment-success.txt` | Direct systemd state, executable paths, and status-only HTTPS checks; high confidence | Does not test authenticated user flows. |
| `auth-mini-service-health` | PASS | `docs/evidence/deployment-success.txt` | Direct systemd state and local/public `/healthz` status checks; high confidence | Does not test login/session behavior. |
| `restore-fidelity` | DEFERRED | `docs/rfc.md` | RFC deferred protocol remains complete | Requires `acorn-vaultwarden-restore-drill`. |

## Attempt 2 Execution Record

- `git diff --check` exited 0; the only production files changed are `flake.nix`, `flake.lock`, `hosts/acorn/modules/vaultwarden.nix`, and `packages/auth-mini/default.nix`.
- Axiom re-read official GitHub asset ID `488807338`; its name and SHA-256 digest converted exactly to the reviewed SRI hash.
- Nix evaluation resolved Vaultwarden `1.37.0`, Web Vault `2026.6.4+0`, and the new auth-mini `ExecStart` while preserving its host, port, and database arguments.
- A fresh SQLite backup succeeded at 13:25:08 CST. The required Axiom `nixos-rebuild switch` completed successfully; both services reached `active/running` at 13:32:56 CST, 7 minutes 48 seconds later.
- Vaultwarden root, direct auth-mini `/healthz`, and public auth `/healthz` each returned HTTP 200 without authenticating or storing response bodies.

## Authority Evidence Update

`auth-mini-asset-provenance` uses the official GitHub Releases asset API for repository `zccz14/auth-mini`. The recorded asset ID, artifact name, state, timestamp, SHA-256 digest, and SRI conversion appear in `docs/evidence/auth-mini-asset.txt`. The full Axiom build independently exercised the asset-ID source and `Accept: application/octet-stream` header. The documentation fetcher transport error for an optional asset endpoint was not used as evidence and did not affect the direct API verification.

## Deferred Claim

`restore-fidelity` remains DEFERRED under the RFC protocol. No current claim treats a successful SQLite backup as proof of full restore ability.

## Verdict

PASS

## 会话注意力摘要

- **阶段**: verify-change
- **阶段结论**: PASS
- **注意力等级**: review
- **判断变化**: auth-mini asset provenance and full Axiom build now pass; the required deployment completed; Vaultwarden and auth-mini are active with non-authenticated health surfaces returning HTTP 200.
- **关键发现**: Vaultwarden is `1.37.0`; auth-mini uses the asset-ID-backed `latest-2026-07-24` binary; fresh backup preceded activation by 7 minutes 48 seconds.
- **阻塞项**: 无。
- **残余风险**: Upstream auth-mini binary lacks an independent audit; health checks exclude login/session flows; `restore-fidelity` remains deferred.
- **人类动作**: 在 merge 或任务 closeout 前复核并接受 auth-mini upstream-binary 与 deferred restore-fidelity 的残余风险。
- **自动下一步**: 进入 `review-change`，只读审查实现范围、证据完整性和生产回归风险。
- **完整证据**: `.legion/tasks/acorn-vaultwarden-package-update/docs/test-report.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/deployment-success.txt`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/auth-mini-asset.txt`

## Handoff

结果: Acorn Vaultwarden Package Update · verify-change · PASS · attention:review
变化: auth-mini source pin 已由官方 asset digest 和完整构建验证；Axiom 构建、传输与激活成功；两项服务与非认证健康面均通过
风险: auth-mini 上游二进制未独立审计；不测试登录/会话；恢复演练仍 deferred，merge/closeout 需用户复核
下一步: 进入 review-change，只读审查范围、部署证据和残余风险；停止 merge/closeout 直到用户复核
证据: `.legion/tasks/acorn-vaultwarden-package-update/docs/test-report.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/deployment-success.txt`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/auth-mini-asset.txt`
