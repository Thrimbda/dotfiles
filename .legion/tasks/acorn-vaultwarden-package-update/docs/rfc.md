# RFC: Acorn Vaultwarden Isolated Package Update

## Executive Summary

将 Acorn 的 Vaultwarden 服务二进制和 Web Vault 资产改为来自一个单独锁定的 `nixpkgs-vaultwarden` 输入。该输入跟踪 `nixos-unstable`，但只由 Acorn 的 Vaultwarden 配置使用；主 `nixpkgs`、现有 `nixpkgs-unstable` 及其他输入保持不变。由于升级密码库服务可能影响持久化数据，本任务按高风险处理：先确认备份链路，再从 Axiom 使用规定的远程构建命令部署，并以服务状态、版本和 HTTPS 可达性验证结果。

## Context

当前 Vaultwarden 服务和 Web Vault 均从主 `nixpkgs` 获取。主输入固定在 `nixos-25.11`，直接更新会改变无关系统包。仓库已有通用 `nixpkgs-unstable`，但它也被多个桌面输入复用；把 Vaultwarden 放入该输入会把未来服务升级与无关不稳定依赖的更新绑定。

截至 2026-07-30，Acorn 上的服务为 `active`，`ExecStart` 指向 `vaultwarden-1.36.0`，本地声明求值同样返回 `1.36.0`。`backup-vaultwarden.timer` 已加载并等待运行，最近一次 `backup-vaultwarden.service` 的结果为 `success`。完整证据见 `docs/research.md`。

## Goals

- 以独立、可复现的 lock 节点更新 Vaultwarden，而不改变主 `nixpkgs` 或现有 `nixpkgs-unstable` 的锁定提交。
- 让 Vaultwarden 服务包和 Web Vault 包从同一输入、同一平台包集获取。
- 保持现有环境文件、SQLite 数据目录、备份目录、Nginx 反向代理和服务配置不变。
- 只从 Axiom 执行 Acorn 的远程构建与切换，并在切换后获得可审计的健康证据。

## Non-goals

- 不直接构建上游 Git 版本、不新增 overlay，也不改用容器化部署。
- 不修改密码库数据、密钥、认证策略、域名、备份保留策略或 Nginx 路由。
- 不在 Acorn 上构建、求值或作为失败后的替代构建主机。
- 不以生产数据执行破坏性的备份恢复演练。

## Options

| 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|
| 更新主 `nixpkgs` | 不增加输入 | 所有稳定系统包一起升级，违背最小更新范围 | 拒绝 |
| 使用现有 `pkgs.unstable.vaultwarden` | 改动少 | 后续更新 Vaultwarden 必须推进共享的 `nixpkgs-unstable`，会影响其他消费者 | 拒绝 |
| 新增独立 `nixpkgs-vaultwarden` 输入 | 将版本更新、锁定和回滚收敛到一个服务专用节点 | 多一个 Nixpkgs 输入，部署闭包可能增大 | 采用 |
| 直接钉住上游源码或新增 overlay | 可追踪未打包提交 | 增加构建、维护和兼容性风险，超出常规升级范围 | 拒绝 |

## Decision

在 `flake.nix` 增加：

```nix
nixpkgs-vaultwarden.url = "nixpkgs/nixos-unstable";
```

通过 `nix flake update nixpkgs-vaultwarden` 仅刷新该输入。Acorn 的 Vaultwarden 模块接受现有的 `hey` 和 `pkgs` 参数，并从以下包集选择同源包：

```nix
hey.inputs.nixpkgs-vaultwarden.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vaultwarden
```

将该值同时赋给 `services.vaultwarden.package` 与其 `.webvault` 赋给 `services.vaultwarden.webVaultPackage`。主 NixOS 模块继续控制系统用户、环境文件、systemd 硬化、SQLite 备份和服务启动。包版本与 Web Vault 属性是否能满足模块接口由实施后的 Nix 求值阻塞验证。

## Scope

- `flake.nix`：添加专用输入。
- `flake.lock`：只增加或更新 `nixpkgs-vaultwarden` 及其 root 引用。
- `hosts/acorn/modules/vaultwarden.nix`：选择同源 `package` 和 `webVaultPackage`，不改其他 Vaultwarden 设置。
- 任务内 RFC、验证、审查和交付文档。

## Verification Plan

### Claim Preregistration

| Claim ID | 主张 | 轴 / 时机 / 专业门槛 | 原始证据与方法 | Criticality / 错误代价 | 阻塞策略 / Owner |
|---|---|---|---|---|---|
| `lock-isolation` | 主 `nixpkgs` 和现有 `nixpkgs-unstable` 的锁定提交未变化 | formal / now / routine | `git diff -- flake.lock` 及锁节点比较 | high / 无关系统依赖被意外升级 | block-stage / engineer |
| `package-compatibility` | Acorn 可从专用输入解析 Vaultwarden 与 Web Vault，且主模块可调用包的 `override` | formal / now / routine | `nix eval` 服务包和 Web Vault 版本、属性与配置 | high / 切换前配置失败 | block-stage / engineer |
| `fresh-package` | 更新后的输入包含更新时 `nixos-unstable` 提供的 Vaultwarden 版本 | objective / now / routine | `nix flake update nixpkgs-vaultwarden` 输出、锁节点和 `nix eval` 版本 | medium / 用户没有获得预期升级 | block-stage / engineer |
| `backup-preflight` | 切换前即时 SQLite 备份成功、时间戳不早于部署前 15 分钟且目录仍存在 | objective / now / routine | 使用用户授权的本地受控凭据启动 Acorn `backup-vaultwarden.service`，随后读取其结果、退出时间和备份目录元数据 | critical / 数据迁移或失败时无法恢复 | block-stage / operator |
| `release-compatibility` | 目标版本相对 `1.36.0` 不需要本 RFC 未覆盖的手工迁移或配置操作 | objective / now / authority | 逐一检查官方 Vaultwarden release notes 覆盖的版本区间，并保存版本、URL、获取时间和结论 | high / 未知迁移或不兼容变更导致停机或不可回滚 | block-stage / engineer |
| `post-switch-health` | 新闭包在 Acorn 激活后，服务运行、版本匹配且 HTTPS 入口可达 | objective / now / routine | `systemctl show`, `ExecStart`, 非认证 HTTPS 状态检查 | critical / 密码库不可用或运行错误版本 | block-stage / operator |
| `restore-fidelity` | 备份可在真实灾难中完整恢复 | objective / deferred / domain | 非生产恢复演练，使用隔离数据和明确演练记录 | high / 备份表面成功但不可恢复 | defer-by-contract / Acorn operator |

没有外部 authority claim；上述检查使用 Nix 求值、Git 锁文件、systemd 和 HTTPS 的脱敏原始输出。`restore-fidelity` 不可由本次无破坏性升级直接证明，不得被表述为已通过。

### Preflight

1. 确认执行机为 Axiom，目标为 Acorn。
2. 在 Acorn 读取 `vaultwarden.service` 的活动状态和当前 `ExecStart` 版本，作为回滚基线。
3. 将每日 `backup-vaultwarden.timer` 的成功结果仅作为基线。使用用户授权的本地受控凭据在部署开始前启动 Acorn `backup-vaultwarden.service`；凭据内容不能被读取、打印、写入日志或加入 Git。随后读取其 `Result`、`ExecMainExitTimestamp` 与 `/backup/vaultwarden` 的目录元数据。只有 `Result=success`、退出时间距切换不超过 15 分钟且目录仍存在时才满足 `backup-preflight`。凭据不可用、sudo 不可获得、启动失败、结果非 success、时间戳过旧或目录不存在时，停止并记录 blocker；不得以昨天的定时备份替代。
4. 更新专用输入并检查锁文件：只能新增 `nixpkgs-vaultwarden`，不能变更主 `nixpkgs` 或现有 `nixpkgs-unstable` 节点。
5. 在 Axiom 执行纯求值，确认服务包与 `webVaultPackage` 来自同一更新输入，记录两者版本。
6. 使用下述 `release-compatibility` 权威证据协议，比较 `1.36.0` 到目标版本的官方发布说明。无法获得完整官方来源，或发现未覆盖的手工迁移、配置变更或回滚限制时，停止部署并返回 RFC。

### Deployment

只从 Axiom 执行以下命令，且不修改其中的 target、build-host 或 substitutes 语义：

```bash
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

此命令失败时停止并记录 build、transfer 或 activation blocker；不得退回到 Acorn 本地构建。即时备份需要的 Acorn sudo 权限不由该命令替代，必须先满足前一节的 `backup-preflight`。

### Post-deployment

1. 读取 `vaultwarden.service` 的 `ActiveState`、`SubState` 与 `ExecStart`，确认版本与 Axiom 的求值结果一致。
2. 对公开 HTTPS 入口执行不带认证、无响应体持久化的状态检查；不登录、不读取 vault 数据、不记录 cookie 或 token。
3. 检查 `backup-vaultwarden.timer` 仍加载并等待，且既有备份目录路径未改变。
4. 将命令、退出状态、版本、锁文件范围和残余风险写入 `docs/test-report.md`。

## Rollback

若纯求值失败、锁文件范围超出预期、备份 preflight 不通过、切换失败，或 post-switch 健康检查失败：停止后续动作。将 `flake.nix`、`flake.lock` 和 Acorn 中的包选择恢复到升级前的已审阅状态，并仍从 Axiom 使用同一远程构建命令重新切换。

若 Vaultwarden 的内部数据迁移使二进制回退不足，停止服务并按既有 `/backup/vaultwarden` 备份的运维恢复流程处理；本 RFC 不将数据库恢复自动化，也不在没有验证过的恢复步骤下继续部署。

## Observability and Residual Risk

- 证据仅记录版本、锁节点、systemd 状态、退出码和 HTTP 状态；不记录环境文件、数据库内容、密钥或用户数据。
- 即时 `backup-vaultwarden.service` 的成功状态并不等于已做完整恢复演练，`restore-fidelity` 保持 `DEFERRED`。
- `nixos-unstable` 的包版本是本任务的可复现升级目标；它不承诺与上游发布零时差。
- 升级期间 Vaultwarden 会重启，短暂服务中断是预期的部署影响。

## Authority Evidence: `release-compatibility`

- **被评价主体**: 从当前运行版本 `1.36.0` 到更新后 `nixpkgs-vaultwarden` 包版本的 Vaultwarden 版本区间。
- **出具主体与资质来源**: `dani-garcia/vaultwarden` GitHub Releases，由上游维护仓库发布。
- **范围与方法**: 获取每个跨越版本的官方 release URL，记录版本、URL、获取时间和发布说明中有关数据库、配置、升级或回滚的内容；版本区间不得跳过。
- **完整性与真实性**: 仅接受 `https://github.com/dani-garcia/vaultwarden/releases/tag/<version>` 的 HTTPS 页面或该仓库对应的 GitHub Releases API 项；记录最终 URL 和 HTTP 结果。第三方博客、搜索摘要和 Nixpkgs commit message 不能替代该证据。
- **有效性与负路径**: 未能读取官方来源、版本区间不完整，或发布说明要求本 RFC 未覆盖的人工操作时，`release-compatibility=INCONCLUSIVE` 或 `FAIL`，阶段为 FAIL，且不得执行 `nixos-rebuild switch`。

## Deferred Verification Protocol: `restore-fidelity`

- **Trigger**: 本次成功部署后 90 天内的计划维护窗口，或任何 `backup-vaultwarden.service` 失败、回滚尝试或存储异常事件，以较早者为准。
- **Owner**: Acorn operator。
- **Method**: 在不可从公网访问、与生产隔离的环境中，从一个由 `backup-vaultwarden.service` 生成的具名快照恢复 Vaultwarden。使用新的测试环境文件和无生产外发能力的网络策略，验证服务能启动、SQLite 数据库可打开且本地健康检查成功；结束后按数据处理规范销毁隔离副本。
- **Required data**: 具名备份快照及其时间戳、与生产隔离的临时 NixOS 环境、专为演练生成的非生产环境文件、命令和脱敏结果记录。
- **Stop condition**: 恢复环境不能启动、数据库不能打开、意外产生公网可达性、或隔离/清理无法保证时立即停止，销毁隔离环境并按失败处置。
- **Successor task**: `acorn-vaultwarden-restore-drill`。
- **On pass**: 记录恢复演练证据，将 `restore-fidelity` 更新为 PASS，并把已验证的恢复步骤写入维护知识库。
- **On fail**: 创建并恢复 `acorn-vaultwarden-restore-drill` 的修复阶段，标记备份恢复风险为未解决；在修复前不将备份成功等同于可恢复。

## Open Questions

- 无。发布兼容性和恢复演练均已登记为带停止条件的验证协议。

## Amendment: Auth-mini Fixed-output Pin Repair

### Context

执行本 RFC 的规定 Axiom build 时，现有 `auth-mini` 固定输出 derivation 在下载阶段发生 hash mismatch。该包为 Acorn 认证服务的二进制来源，因而其内容更新属于高风险认证边界变更，尽管 service configuration、数据库、gateway 和路由均不变。

官方 `zccz14/auth-mini` latest-release API 表明 release tag 就是 mutable `latest`，`immutable=false`，不存在可替代的版本 tag。当前 x86_64 Linux asset 的 ID 为 `488807338`，官方 digest 为 `680221287e0cca77311acf6b5c9743089d88d9115332ba83a9f3ce35de908922`。经 Axiom 的 `nix hash convert --hash-algo sha256 --to sri` 转换后，该值与 Nix 构建实际下载并报告的 `sha256-aAIhKH4MyncxGs9rXJdDCJ2I2RFTMrqDqfPONd6QiSI=` 一致。

### Options

| 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|
| 只更新 hash，保留 `/download/latest/` | 单行改动 | 下次 upstream 替换 latest asset 时再次阻断构建，且旧源码不可重建 | 拒绝 |
| 使用官方 asset-ID API endpoint、header 和固定 hash | 锁定到具体上传 asset；未来 API/asset 变化安全失败；可交叉验证官方 digest | 多一个 `curlOpts` header，asset 删除会导致受控构建失败 | 采用 |
| 从 upstream source 构建 | 可自行选择 commit | 改变打包与运行时风险，超出本次 package-only 修复范围 | 拒绝 |

### Decision

仅修改 `packages/auth-mini/default.nix` 的 source reference、版本元数据和 fixed-output hash：

```nix
version = "latest-2026-07-24";

src = fetchurl {
  url = "https://api.github.com/repos/zccz14/auth-mini/releases/assets/488807338";
  curlOpts = "--header Accept:application/octet-stream";
  hash = "sha256-aAIhKH4MyncxGs9rXJdDCJ2I2RFTMrqDqfPONd6QiSI=";
};
```

Nixpkgs documents `fetchurl` support for `curlOpts`; the current Nixpkgs tree uses the same string form for GitHub `Accept` headers. No `auth-mini.nix` service configuration, `auth-mini-gateway`, environment file, data directory, route, or secret changes are permitted.

### Claim Preregistration

| Claim ID | 主张 | 轴 / 时机 / 专业门槛 | 原始证据与方法 | Criticality / 错误代价 | 阻塞策略 / Owner |
|---|---|---|---|---|---|
| `auth-mini-asset-provenance` | asset ID `488807338` and SRI hash identify the official current x86_64 Linux auth-mini artifact | objective / now / authority | Official GitHub Releases API asset record, hex-to-SRI conversion, and exact Axiom fetch mismatch output | high / accept an unintended authentication binary | block-stage / engineer |
| `auth-mini-fetch-compatibility` | `fetchurl` with the API URL and content-negotiation header fetches the pinned artifact during the Axiom Acorn build | formal / now / routine | Required `nixos-rebuild switch` build output | high / complete system cannot build or fetched content differs | block-stage / engineer |
| `auth-mini-service-health` | auth-mini restarts on the updated package and remains active with non-authenticated `/healthz` returning HTTP 200 | objective / now / routine | Acorn `systemctl show auth-mini` and local/public status-only curl checks | critical / authentication service outage | block-stage / operator |

Authority evidence is accepted only when the official API response identifies repository `zccz14/auth-mini`, asset name `auth-mini-linux-x86_64.tar.gz`, asset ID `488807338`, and the stated digest. A source mismatch, conversion mismatch, API failure, unexpected redirect behavior, or Nix hash mismatch yields FAIL and stops deployment.

### Verification and Deployment Restart

1. Re-check source provenance before changing the package: API asset identity and digest must still match the specified SRI hash. Do not persist temporary signed redirect URLs.
2. Apply only the reviewed package-file edit and use a local Axiom configuration evaluation to confirm the auth-mini `ExecStart` references the new package version.
3. Re-run the complete prescribed `nixos-rebuild switch` command from Axiom. The earlier Vaultwarden backup is no longer within the 15-minute deployment bound, so first create and verify a fresh `backup-vaultwarden.service` backup using the approved local credential process.
4. After a successful switch, check Vaultwarden service/version/HTTPS as in the base RFC and check `auth-mini.service` `ActiveState=active`, `SubState=running`, plus HTTP 200 for `http://127.0.0.1:7777/healthz` and `https://auth.0xc1.wang/healthz`. Do not exercise login, session, admin, or database endpoints.

### Rollback

If package fetch, build, service activation, or health checks fail, stop without Acorn-local building. The prior Acorn system generation remains the emergency rollback boundary because its closure includes the previously running auth-mini binary; this RFC does not automate generation rollback or alter host recovery policy. For a normal source rollback, retain the new asset-ID source and hash as the reproducible repaired baseline; do not restore the old mutable URL plus obsolete hash because it no longer resolves to its declared content.
