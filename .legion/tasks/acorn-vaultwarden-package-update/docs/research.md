# Acorn Vaultwarden Package Update Research

## 现状证据

| 观察 | 证据 | 含义 |
|---|---|---|
| 主输入固定在 `nixos-25.11` | `flake.nix:16` | 直接更新 `nixpkgs` 会升级 Acorn 的其他稳定包。 |
| 已有 `nixpkgs-unstable` 被多个桌面输入复用 | `flake.nix:17,35,37,39,54,57` | 复用它会使以后的 Vaultwarden 更新与无关不稳定包绑定。 |
| 模块可访问 `hey.inputs` | `lib/nixos.nix:139-142,205-206,254-259` | 新 flake 输入无需扩大通用 `specialArgs`，可由 Acorn 模块直接引用。 |
| Acorn 的 Vaultwarden 配置未覆盖包来源 | `hosts/acorn/modules/vaultwarden.nix:25-45` | 当前服务和网页客户端均来自主 `nixpkgs` 的默认值。 |
| 当前服务正常运行，服务二进制为 `vaultwarden-1.36.0` | Acorn `systemctl show vaultwarden --property=ExecStart --property=ActiveState --property=SubState`，2026-07-30 | 当前部署版本和健康基线为 `1.36.0` / `active`。 |
| 本地配置求值的服务包版本也是 `1.36.0` | Axiom `nix eval --raw .#nixosConfigurations.acorn.config.services.vaultwarden.package.version`，2026-07-30 | 声明和运行中的服务版本一致。 |
| NixOS 模块有独立的 `package` 与 `webVaultPackage` 选项 | Nixpkgs module `default.nix:203-205` | 服务包升级必须同时考虑网页客户端，不能只设置 `package`。 |
| 当前 Web Vault 版本为 `2026.4.1+0` | Axiom 对 `pkgs.vaultwarden.webvault.version` 和配置默认值的求值，2026-07-30 | 应从同一新输入取 `webvault`，避免服务与网页资产跨版本。 |
| 备份目录存在；`backup-vaultwarden.timer` 等待中，最近一次 `backup-vaultwarden.service` 成功 | Acorn `stat /backup/vaultwarden` 及 `systemctl show backup-vaultwarden.{timer,service}`，2026-07-30 | NixOS SQLite 备份链路存在；切换前仍须验证最近成功结果和目录可访问性。 |
| 非交互式远程 `sudo` 不可用 | Acorn `sudo -n true`，2026-07-30，返回“需要密码” | 即时备份需要本地受控凭据；用户已授权使用未追踪的本地凭据，且其内容不得读取、输出、记录或提交。 |

## 模块语义

主 `nixpkgs` 的 Vaultwarden NixOS 模块将 `services.vaultwarden.package` 作为可覆盖包，并以 `cfg.package.override { dbBackend = cfg.dbBackend; }` 启动服务。设置 `backupDir` 时，它创建 `backup-vaultwarden.service` 与每天 23:00 触发的持久化 `backup-vaultwarden.timer`。这些结论来自当前主输入的 `nixos/modules/services/security/vaultwarden/default.nix:67,203-205,323-350`。

因此，独立输入的包必须在 Acorn 的 `x86_64-linux` 平台上求值，支持模块使用的 `override` 调用，并暴露 `webvault`。这些均在实施后的纯求值检查中阻塞验证。

## 未知项和边界

- `nixos-unstable` 在锁定更新时提供的具体 Vaultwarden 和 Web Vault 版本尚未知；以更新后的 flake 锁和 `nix eval` 输出为准。
- Vaultwarden 版本升级可能触发内部 SQLite 数据迁移。此次不手工修改数据库，也不声明无需迁移；切换前的成功备份是阻塞前提。
- 本次只能证明备份任务最近成功和目录存在，不能在生产数据上执行破坏性的恢复演练。完整恢复能力保留为运维残余风险。
- Acorn 的远程 sudo 不能在无凭据的非交互式 SSH 中获得授权；即时备份只可使用用户授权的本地受控凭据，并且不能把凭据内容写入仓库、日志或命令输出。

## Auth-mini Fixed-output Pin Research

| 观察 | 证据 | 含义 |
|---|---|---|
| 现有包从可变 `latest` tag 下载，版本元数据仍为 `latest-2026-07-12` | `packages/auth-mini/default.nix:9-15` | 已有固定输出哈希会在 upstream 替换 latest asset 时阻断构建，且无法从原 URL 重建旧内容。 |
| 完整 Acorn 构建下载内容与旧 pin 不匹配 | Axiom `nixos-rebuild switch` 输出 | 预期 `sha256-OFLk...`，实际为 `sha256-aAIhKH4MyncxGs9rXJdDCJ2I2RFTMrqDqfPONd6QiSI=`；失败发生在 Axiom 构建阶段。 |
| 官方 latest release 没有版本 tag，且 `immutable=false` | `https://api.github.com/repos/zccz14/auth-mini/releases/latest`，2026-07-30 | 不能将 URL 改为不存在的 version tag；继续使用 `/download/latest/` 会再次漂移。 |
| 官方 API 将 Linux asset 标识为 `488807338`，并给出 SHA-256 digest `680221287e0cca77311acf6b5c9743089d88d9115332ba83a9f3ce35de908922` | 同一官方 API response | 可使用 asset-ID API endpoint 作为具体 release asset 的来源，并以 digest 验证内容。 |
| 官方 digest 转 SRI 后与 Nix 构建实际下载 hash 一致 | `nix hash convert --hash-algo sha256 --to sri 680221...`，输出 `sha256-aAIhKH4MyncxGs9rXJdDCJ2I2RFTMrqDqfPONd6QiSI=` | API authority evidence 与 Nix fetch failure 的内容证据交叉匹配。 |
| asset-ID endpoint 可在 `Accept: application/octet-stream` 下返回下载内容 | Axiom `curl --location --header "Accept: application/octet-stream" .../assets/488807338` 返回 HTTP 200，2026-07-30 | Nixpkgs `fetchurl` 可使用 `curlOpts` 添加同一 header；不持久化临时签名重定向 URL。 |
| auth-mini 当前正常 | Acorn `systemctl show auth-mini` 为 `active/running`，`http://127.0.0.1:7777/healthz` 和 `https://auth.0xc1.wang/healthz` 均为 HTTP 200 | 可在部署后使用相同的非认证健康面验证包更新，没有必要测试登录或读取数据。 |

### Source Choice

保留 mutable `latest` URL 只更新 hash 的改动更小，但会再次失去可重建性。上游没有不可变版本 tag，因此采用官方 asset-ID API endpoint 加 `Accept: application/octet-stream` header。固定输出 hash 仍验证实际内容；若该 asset 被删除、API 协议变化或内容不符，构建会失败而非静默替换认证二进制。
- 上游最新发布与 `nixos-unstable` 打包版本可能存在时间差。本任务的“最新”定义为更新时 `nixos-unstable` 可复现地提供的版本，而不是未打包的上游 Git 提交。
