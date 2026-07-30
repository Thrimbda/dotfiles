# Change Review: Acorn Vaultwarden Package Update

## Scope Review

PASS. The production diff is limited to the approved files:

- `flake.nix` and `flake.lock`: add the isolated `nixpkgs-vaultwarden` input only.
- `hosts/acorn/modules/vaultwarden.nix`: use that input for synchronized server and Web Vault packages.
- `packages/auth-mini/default.nix`: replace the mutable release URL with the reviewed asset-ID API endpoint, add the required content-negotiation header, and update only version metadata and fixed-output hash.

No service configuration, secret, database path, domain, route, gateway, user, or policy change is present. `git diff --check` passed.

## Correctness Review

- The primary `nixpkgs` and existing `nixpkgs-unstable` lock revisions are unchanged; only the dedicated Vaultwarden node was added.
- Acorn evaluation resolves `vaultwarden-1.37.0`, matching the deployed `ExecStart`, and keeps Web Vault at the matching selected package-set version `2026.6.4+0`.
- The auth-mini API asset ID, official digest, SRI conversion, `fetchurl` header behavior, and full Axiom closure build agree on the new `latest-2026-07-24` derivation.
- The required Axiom build, remote closure transfer, and Acorn activation completed successfully. Both changed services were restarted and are `active/running`.

## Evidence Review

- `docs/evidence/lock-and-eval.txt` provides raw lock and evaluation output for the isolated package source.
- `docs/evidence/release-1.37.0.txt` provides the official Vaultwarden release evidence over the deployed version interval.
- `docs/evidence/auth-mini-asset.txt` records the official GitHub asset identity, digest, and deterministic SRI conversion.
- `docs/evidence/deployment-success.txt` records fresh-backup timing, exact deployment command, successful asset fetch/build/transfer/activation, and status-only health checks.
- `docs/test-report.md` maps each registered claim to evidence and has a current PASS verdict. The historical Attempt 1 failure remains clearly labeled and does not override the successful Attempt 2 result.

## Security Lens

Applicable because the change updates a password-manager service and an authentication-service binary.

- The Vaultwarden upgrade preserves existing secret injection, data directory, backup configuration, and reverse-proxy settings; no secret values appear in the diff or evidence.
- Auth-mini is now fetched through a concrete official asset-ID endpoint and verified by a fixed-output hash. The required system build independently checked that the endpoint and header retrieve that exact content.
- Health checks deliberately use only service state and unauthenticated HTTP status codes. They do not submit credentials, inspect sessions, or read database data.
- The upstream auth-mini binary has no independent code audit or separate signing evidence in this task. The GitHub API source and fixed hash protect integrity at build time but do not prove behavior beyond the non-authenticated health surface.

## Findings

No blocking findings.

Non-blocking follow-ups:

- Execute the already defined `acorn-vaultwarden-restore-drill` within 90 days or sooner if a backup, rollback, or storage anomaly occurs.
- Re-evaluate auth-mini source provenance if its asset-ID endpoint or upstream release process changes before the next update.

## Verdict

PASS

## 会话注意力摘要

- **阶段**: review-change
- **阶段结论**: PASS
- **注意力等级**: review
- **判断变化**: 完整 Axiom build、远程 activation 和 Vaultwarden/auth-mini 非认证健康检查均成功；Attempt 1 的 hash blocker 已由受审阅的 asset-ID pin 解决。
- **关键发现**: production scope 保持最小；所有 critical deployment claims 有直接证据；auth-mini upstream binary audit 和 restore fidelity 仍未完成。
- **阻塞项**: 无。
- **残余风险**: auth-mini binary is trusted through upstream GitHub asset integrity rather than independent audit; login/session behavior was intentionally not exercised; `restore-fidelity` remains deferred.
- **人类动作**: 在 merge 或任务 closeout 前复核并接受 auth-mini upstream-binary 与 deferred restore-fidelity 的残余风险。
- **自动下一步**: 进入 `report-walkthrough`，生成交付摘要；不执行 merge 或 task closeout，直到人类复核落盘。
- **完整证据**: `.legion/tasks/acorn-vaultwarden-package-update/docs/review-change.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/test-report.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/deployment-success.txt`

## Handoff

结果: Acorn Vaultwarden Package Update · review-change · PASS · attention:review
变化: 初始 auth-mini hash blocker 已修复；Axiom build、transfer、activation 与两项服务健康检查均成功；生产 diff 严格限于批准范围
风险: auth-mini upstream binary 未独立审计；不测试登录/会话；恢复演练仍 deferred，merge/closeout 需用户复核
下一步: 进入 report-walkthrough 生成交付材料；停止 merge 和 task closeout 直到用户复核残余风险
证据: `.legion/tasks/acorn-vaultwarden-package-update/docs/review-change.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/test-report.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/evidence/deployment-success.txt`
