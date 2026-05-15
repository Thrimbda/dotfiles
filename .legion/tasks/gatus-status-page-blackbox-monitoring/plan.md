# Gatus Status Page Blackbox Monitoring

## Task Metadata

- **name**: Gatus Status Page Blackbox Monitoring
- **taskId**: gatus-status-page-blackbox-monitoring
- **source**: Linear 0XC-7 - https://linear.app/0xc1/issue/0XC-7/搭建-gatus-作为服务状态页与黑盒监控入口

## 目标

在 dotfiles/NixOS 配置中搭建第一版 Gatus，使它成为服务状态页与黑盒监控入口，并把 endpoint、Prometheus scrape 形状和运维说明纳入 repo review。

## 问题陈述

当前仓库已有 Prometheus 模块骨架和若干公网/隧道服务配置，但缺少从用户视角持续探测公网入口、关键 HTTP endpoint、TCP 可达性与证书有效期的状态页。Prometheus 适合 white-box metrics，不能替代 black-box 探测与对外状态展示；Gatus 更适合用 config-as-code 管理 endpoint inventory、健康条件和 Prometheus `/metrics` 暴露。

## 验收标准

- [ ] NixOS 配置中存在可启用的 Gatus 服务封装，默认开启 `/metrics`，使用 sqlite 持久化，并监听本机端口。
- [ ] `acorn` 获得第一版 Gatus 部署配置和反向代理入口，status page 可通过明确域名访问或通过人工 DNS/ACME 项上线。
- [ ] 至少 3 个核心 endpoint 被纳入配置，覆盖公网 HTTP、TLS 证书有效期、Gatus 自身健康或关键 TCP/隧道服务可达性。
- [ ] Prometheus scrape 配置形状落盘或由模块生成，能抓取 Gatus `/metrics`。
- [ ] README/runbook 说明如何新增 endpoint、如何本地验证配置、如何访问 status page、如何查询 Gatus 指标，以及 Gatus 自身异常时如何处理。
- [ ] 文档明确 Gatus 与 Prometheus 的边界：Gatus 做黑盒可用性和状态页，Prometheus 继续做系统/应用指标。
- [ ] Legion 文档记录设计、验证、评审和交付状态。

## 假设

- **部署目标**: 第一版落在 NixOS/acorn，而不是 Docker Compose。仓库已经以 NixOS host/module 为主，`acorn` 是 server profile 且已有 nginx、vaultwarden 与公网域名配置。
- **公开入口**: 第一版使用 `status.0xc1.space` 作为推荐域名；DNS/ACME 是否已就绪需要上线时人工确认。
- **endpoint inventory**: 第一版从仓库已知服务起步，优先覆盖 `vault.0xc1.space`、Gatus 自身 loopback endpoint、opencode cloudflared hostnames 或 SSH TCP 可达性中的安全子集。
- **Prometheus**: 第一版只把 scrape target 形状纳入配置，不要求现有 Prometheus 已经在某台 host 上完整启用和长期存储。
- **告警**: 第一版不直连 Slack/Discord/Telegram/Email；先通过 Gatus status page 和 Prometheus metrics 支撑后续 Alertmanager 告警。

## 约束

- 遵守 Legion workflow；稳定 contract 后进入 `git-worktree-pr` envelope 执行修改型开发任务。
- 不把业务 white-box metrics、应用内部指标或 incident workflow 塞进 Gatus。
- 不提交明文 secret，不新增需要未加密 token 的部署路径。
- 不在本任务中执行实体主机 `nixos-rebuild switch`，除非用户另行确认。
- 保持现有 vaultwarden、cloudflared、opencode 暴露行为不被重构。

## 风险

- **Medium**: 涉及公网状态页、nginx/ACME、Prometheus scrape 与 NixOS service 组合，错误配置可能导致 Gatus 不可访问或暴露范围不符合预期。
- Gatus 的 NixOS module/options 依赖当前 nixpkgs 版本；需要通过 eval/build 验证 option shape。
- DNS、ACME、外部域名和远端 endpoint 可达性依赖外部状态，自动验证可能只能覆盖配置形状。
- 如果 endpoint 选择过多或过敏感，可能把内部服务暴露在公开状态页上；第一版应优先选择公开服务和 loopback 自检。

## 范围

- `modules/services/gatus.nix` 或等价服务模块封装。
- `hosts/acorn/**` 中的 Gatus host enablement、nginx vhost、endpoint inventory 和 runbook 入口。
- `modules/services/prometheus.nix` 中必要的 Gatus scrape 支持或示例配置。
- `docs/**` 或 host-local README/runbook 中的 status page 运维文档。
- `.legion/tasks/gatus-status-page-blackbox-monitoring/**` 中的 task evidence。
- `.legion/wiki/**` 中的最终 closing writeback。

## 非目标

- 不用 Gatus 替代 Prometheus 的 white-box monitoring。
- 不在第一版实现复杂 incident workflow、on-call 升级或多渠道告警。
- 不把所有业务指标塞进 Gatus；业务指标仍走 app metrics -> Prometheus。
- 不迁移到 Kubernetes，也不引入 Docker Compose 作为本仓库第一版部署路径。
- 不替用户完成 DNS 控制台、Cloudflare Access policy 或实体主机切换部署。

## 设计概要

- **NixOS first**: 采用 `services.gatus` NixOS module，通过仓库自有 `modules.services.gatus` 封装默认端口、sqlite 存储、metrics、endpoint 合并与可选 nginx vhost。
- **Acorn first**: 在 `acorn` 这个 server host 上启用第一版，因为它已有 nginx/ACME 和 `vault.0xc1.space` 公网服务。
- **Config-as-code inventory**: endpoint 使用 Nix attr/list 表达，保留 group 和 `extra-labels`，让 endpoint 变更通过 repo diff review。
- **Prometheus handoff**: Gatus 暴露 `/metrics`；Prometheus 模块获得可选 scrape job 或文档化 static config，第一版不强制完整 Prometheus 拓扑。
- **Safe public surface**: status page 通过 nginx 代理到 loopback Gatus；endpoint 初版避免加入敏感内网-only 服务详情。

## 阶段概览

1. **Contract** - 固化 Linear 0XC-7 的目标、scope、验收、假设和风险。
2. **Design** - 形成 Gatus/NixOS/acorn/Prometheus 设计门，覆盖回滚、验证和公开入口边界。
3. **Implementation** - 在 worktree 中实现 bounded dotfiles 变更。
4. **Verification** - 运行 targeted Nix eval/build 和静态配置检查，记录外部验证缺口。
5. **Delivery** - 完成 change review、walkthrough、wiki writeback 和 PR lifecycle。

## 设计索引

> **Design Source of Truth**: `.legion/tasks/gatus-status-page-blackbox-monitoring/docs/rfc.md`

**摘要**:
- 核心路线: 采用 NixOS/acorn 部署 Gatus，使用 nginx 代理 `status.0xc1.space`，sqlite 持久化，endpoint inventory 纳入 Nix 配置。
- Prometheus: `acorn` 同步启用 Prometheus，并由 Gatus wrapper 追加 `/metrics` scrape job。
- 验证策略: 以 targeted Nix eval/build 验证配置形状；DNS/ACME/status page runtime 作为部署后人工验证项。

---

*Created: 2026-05-15 | Updated: 2026-05-15*
