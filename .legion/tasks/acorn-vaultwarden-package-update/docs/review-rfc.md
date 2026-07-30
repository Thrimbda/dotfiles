# RFC Review: Acorn Vaultwarden Isolated Package Update

## Review Round 1: Blocking Finding (Resolved)

### R1: `backup-preflight` lacks a freshness boundary and executable stop condition

- **Location**: `docs/rfc.md:68,76-80`
- **Impact**: The RFC treats a prior successful `backup-vaultwarden.service` result as sufficient but does not define how recent it must be, whether a new backup must be created immediately before the database-affecting switch, or what exact result stops deployment. A stale or merely historical backup cannot support the critical `backup-preflight` claim.
- **Why blocking**: A Vaultwarden package upgrade can change runtime behavior or migrate persistent SQLite data. Without a defined fresh-backup procedure, the rollback path may be unusable exactly when it is needed.
- **Minimum fix**: Require a successful `backup-vaultwarden.service` run immediately before deployment, record its exit/result and timestamp, verify the backup directory after that run without exposing its contents, and state that any failure prevents `nixos-rebuild switch`. Keep the prior timer result only as baseline evidence.

## Review Round 1: Non-blocking Findings

- Pairing `services.vaultwarden.package` with `services.vaultwarden.webVaultPackage` correctly avoids serving the old Web Vault assets after the server upgrade.
- The proposal correctly avoids modifying global `specialArgs`: `hey.inputs` already exposes new flake inputs to host modules.
- `restore-fidelity` is appropriately recorded as `DEFERRED`; the RFC must not claim a successful backup service is a full restore test.

## Review Round 1 Verdict

FAIL

## Review Round 1 会话注意力摘要

- **阶段**: review-rfc
- **阶段结论**: FAIL
- **注意力等级**: skim
- **判断变化**: 高风险设计需要将“最近成功的备份”收敛为部署前即时、可观测且失败即停止的备份门禁。
- **关键发现**: R1 是唯一阻塞项；服务包与 Web Vault 同源选择合理；完整恢复演练仍为已登记的 deferred 风险。
- **阻塞项**: `backup-preflight` 未定义新鲜度、执行步骤和失败停止条件。
- **残余风险**: 即时备份的成功不能证明真实恢复保真度；该风险保留为 `restore-fidelity` 的 deferred 后续验证。
- **人类动作**: 无动作。
- **自动下一步**: 返回 `spec-rfc` 补齐 R1 后重新运行 `review-rfc`；在 PASS 前不得改生产配置。
- **完整证据**: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`

## Review Round 1 Handoff

结果: Acorn Vaultwarden Package Update · review-rfc · FAIL · attention:skim
变化: 补齐 critical `backup-preflight` 的即时备份、时间戳与失败停止条件；服务和 Web Vault 同源设计可保留；恢复保真度仍为 deferred
风险: 未定义新鲜备份会使数据库迁移后的回滚不可验证；完整恢复演练尚未执行
下一步: 自动返回 spec-rfc，补齐 R1 后重新审查
证据: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`

## Review Round 2: Blocking Findings

### R2: `restore-fidelity` deferred claim lacks the required deferred verification protocol

- **Location**: `docs/rfc.md:70,108,115`
- **Impact**: The RFC classifies restore fidelity as `DEFERRED` but does not specify its trigger, required data, stop condition, successor task, or distinct pass/fail follow-up. A bare future recommendation cannot support a high-risk deferred claim.
- **Why blocking**: The design relies on backups as the recovery boundary for a credential service. Deferral is acceptable only if it gives an operator an executable, bounded recovery-verification path without silently converting an unproven property into an accepted fact.
- **Minimum fix**: Add a complete deferred protocol with owner, scheduled or event trigger, isolated restore method, protected required data, stop condition, named successor task, and pass/fail dispositions.

### R3: Migration-compatibility review has no authoritative source or stop condition

- **Location**: `docs/rfc.md:112-115`
- **Impact**: The RFC says to inspect package metadata and release notes after selecting a target version, but neither defines the official source nor what result blocks deployment. This leaves a possible manual migration or compatibility requirement to ad-hoc judgment.
- **Why blocking**: A version transition from the deployed `1.36.0` can alter database or configuration expectations. Continuing without a bounded compatibility check makes the preflight neither reproducible nor safely falsifiable.
- **Minimum fix**: Register a release-compatibility claim that uses the official Vaultwarden release notes for the version range, records the authority evidence, and stops deployment if notes cannot be obtained or describe required manual migration/configuration work.

## Review Round 2: Non-blocking Findings

- R1 is resolved: the revised RFC now requires an immediate successful backup no older than 15 minutes and explicitly stops when remote sudo or backup evidence is unavailable.
- The remote sudo limitation is correctly treated as an operational prerequisite rather than a reason to weaken Acorn build safety.

## Review Round 2 Verdict

FAIL

## Review Round 2 会话注意力摘要

- **阶段**: review-rfc
- **阶段结论**: FAIL
- **注意力等级**: skim
- **判断变化**: R1 已解决；高风险 RFC 仍需把 deferred restore 验证和发布迁移检查从开放问题收敛为可执行协议。
- **关键发现**: R2 缺完整 deferredProtocol；R3 缺权威 release compatibility 方法与停止条件；即时备份门禁已足够明确。
- **阻塞项**: `restore-fidelity` 的 deferred protocol 不完整；`release-compatibility` 未注册为可验证的发布前 claim。
- **残余风险**: 即使本次立即备份通过，完整恢复仍要在隔离环境中验证；上游发布说明只能覆盖已公布的变更。
- **人类动作**: 无动作。
- **自动下一步**: 返回 `spec-rfc` 补齐 R2、R3 后重新运行 `review-rfc`；在 PASS 前不得改生产配置。
- **完整证据**: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`

## Review Round 2 Handoff

结果: Acorn Vaultwarden Package Update · review-rfc · FAIL · attention:skim
变化: 即时备份门禁已通过设计审查；补齐 deferred restore 协议；补齐带权威来源和停止条件的迁移兼容性检查
风险: 未完成恢复演练协议会使高风险 deferred claim 不可审计；未知发布迁移要求可能阻断回滚
下一步: 自动返回 spec-rfc，补齐 R2 和 R3 后重新审查
证据: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`

## Review Round 3: Resolution

- R1 is resolved: `backup-preflight` now requires an immediate successful backup, a 15-minute freshness bound, and explicit stop conditions. The locally managed credential is an authorized runtime mechanism and is not included in repository artifacts.
- R2 is resolved: `restore-fidelity` has a trigger, owner, isolated method, protected required data, stop condition, successor task, and distinct pass/fail dispositions.
- R3 is resolved: `release-compatibility` now requires official Vaultwarden release evidence across the whole version interval and blocks deployment when that evidence is incomplete or calls for uncovered manual work.

## Review Round 3: Non-blocking Observations

- A successful backup does not prove restore fidelity. The complete deferred protocol preserves that risk without overstating current evidence.
- Exact target-version release notes can only be collected after the dedicated input is updated. This is correctly a deployment preflight rather than a design assumption.

## Review Round 3 Verdict

PASS

## Review Round 3 会话注意力摘要

- **阶段**: review-rfc
- **阶段结论**: PASS
- **注意力等级**: review
- **判断变化**: RFC 已加入可执行的即时备份门禁、官方版本兼容性检查和完整 restore-fidelity deferred protocol。
- **关键发现**: R1-R3 已解决；服务和 Web Vault 保持同源；完整恢复演练仍为高风险 deferred 验证。
- **阻塞项**: 无。
- **残余风险**: 包升级仍可能触发内部数据迁移；即时备份只能降低风险，不能替代隔离恢复演练；官方 release notes 可能揭示需额外 RFC 的手工步骤。
- **人类动作**: 在 merge 或任务 closeout 前复核并接受 `restore-fidelity` 的 deferred 风险和后续演练协议。
- **自动下一步**: 进入 `engineer`，在 worktree 内实现专用输入与同源包选择；若 release compatibility 或 backup preflight 失败，停止部署并回到 RFC。
- **完整证据**: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`

## Review Round 3 Handoff

结果: Acorn Vaultwarden Package Update · review-rfc · PASS · attention:review
变化: 即时备份门禁可执行；官方发布兼容性检查已预注册；恢复演练保留为有完整协议的 deferred 验证
风险: 数据迁移和恢复保真度不能由本次无破坏性部署完全证明；release notes 可能要求返回 RFC
下一步: 进入 engineer；merge 或任务 closeout 前由用户复核 deferred restore-fidelity 风险并停止 merge/closeout 直到复核
证据: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`

## Review Round 4: Auth-mini Fixed-output Pin Amendment

### Findings

- The amendment keeps the change at the package boundary: source reference, version metadata, content-negotiation header, and fixed-output hash. It does not expand into auth-mini configuration, credentials, data, gateway behavior, or routes.
- The chosen asset-ID API endpoint is a better fit than a nonexistent immutable release tag. GitHub API asset identity, its official SHA-256 digest, the deterministic hex-to-SRI conversion, and the prior Nix download result create an evidence chain that can fail closed at build time.
- The optional upstream `.sha256` asset could not be fetched through the documentation fetcher, but this is non-blocking: the official API digest and Nix fixed-output verification are the declared authority and independent content checks. No third-party checksum is used.
- The rollback boundary is explicit: do not attempt to reconstruct the obsolete mutable latest URL; retain the existing Acorn generation for emergency recovery and stop on any new fetch, build, activation, or health failure.

### Non-blocking Residual Risk

- The GitHub release itself is mutable and is not signed by a separate release-key workflow in the evidence available here. The asset ID plus fixed-output hash protects later builds from silent content replacement but cannot independently audit the upstream binary's behavior.
- The auth-mini service health checks prove process and unauthenticated endpoint availability, not login or session correctness. That limitation is deliberate to avoid touching authentication data during this task.

## Verdict

PASS

## 会话注意力摘要

- **阶段**: review-rfc
- **阶段结论**: PASS
- **注意力等级**: review
- **判断变化**: 用户已授权的范围扩展被收敛为 asset-ID source、header、版本元数据和 hash 的 package-only 变更。
- **关键发现**: 官方 API digest 与 Nix SRI 证据一致；不存在不可变 version tag；认证服务健康检查已限定为非认证 surface。
- **阻塞项**: 无。
- **残余风险**: 上游二进制没有独立签名审计；健康检查不覆盖登录/会话正确性；完整恢复演练仍为 deferred。
- **人类动作**: 在 merge 或任务 closeout 前复核并接受 auth-mini upstream-binary 与 deferred restore-fidelity 的残余风险。
- **自动下一步**: 进入 `engineer`，仅修改 `packages/auth-mini/default.nix` 的已审阅字段；之后重跑完整 Axiom 部署验证。
- **完整证据**: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`

## Handoff

结果: Acorn Vaultwarden Package Update · review-rfc · PASS · attention:review
变化: auth-mini 修复收敛为 asset-ID source、header、版本和 hash；来源链可由官方 API、SRI 转换和完整构建复核；健康检查不触碰认证数据
风险: 上游二进制行为未获独立审计；恢复演练仍为 deferred；merge/closeout 仍需用户复核
下一步: 进入 engineer，仅实现 reviewed auth-mini package pin，然后从 Axiom 重跑完整部署和健康验证
证据: `.legion/tasks/acorn-vaultwarden-package-update/docs/rfc.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/research.md`; `.legion/tasks/acorn-vaultwarden-package-update/docs/review-rfc.md`
