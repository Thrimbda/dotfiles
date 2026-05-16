# Gatus Axiom Cloudflare Access

## Task Metadata

- **name**: Gatus Axiom Cloudflare Access
- **taskId**: gatus-axiom-cloudflare-access
- **source**: follow-up to Linear `0XC-7` / `gatus-status-page-blackbox-monitoring`

## 目标

把 Gatus 的对外入口调整为 `status-axiom.0xc1.space`，并按 `opencode-axiom.0xc1.space` 的模式通过 `axiom` 的 cloudflared tunnel 和 Cloudflare Access 保护访问。

## 问题陈述

上一版把 Gatus 部署在 `acorn` 并通过 nginx/ACME 暴露为 `status.0xc1.space`。用户现在希望入口语义跟 `axiom` 的 opencode 暴露保持一致：域名体现 host、传输走 cloudflared、认证由 Cloudflare Access 负责。若继续保留 `acorn` nginx 入口，会同时存在两个 status page public surfaces，并且缺少和 opencode 相同的 Access 控制边界。

## 验收标准

- [ ] 采用 `status-axiom.0xc1.space` 作为唯一新对外入口；不使用 `status.axiom.0xc1.space`。
- [ ] `axiom` 本机启用 Gatus，Gatus 仍绑定 loopback，Prometheus scrape 仍可读取本地 `/metrics`。
- [ ] `axiom` 的 `modules.services.cloudflared.extraConfig.ingress` 新增 `status-axiom.0xc1.space -> http://127.0.0.1:8080`，并保留现有 `opencode-axiom.0xc1.space` ingress。
- [ ] 旧 `acorn` status page 公网入口被移除，避免 `status.0xc1.space` 与 `status-axiom.0xc1.space` 双入口并存。
- [ ] Cloudflare 侧存在 `status-axiom.0xc1.space` route/DNS，并有 Access self-hosted application 保护。
- [ ] Cloudflare Access 策略与当前 `opencode-axiom.0xc1.space` 一致：Google IdP，exact-email allowlist `c1@ntnl.io`、`siyuan.arc@gmail.com`、`froggy2818@gmail.com`，无 broad domain/everyone/bypass allow。
- [ ] 文档、Legion evidence、wiki 和 Linear 状态更新反映新入口和部署位置。

## 假设

- `status-axiom.0xc1.space` 比 `status.axiom.0xc1.space` 更适合当前仓库命名，因为现有 host-specific 服务使用 `service-host.0xc1.space`，例如 `opencode-axiom.0xc1.space`。
- `axiom` 已有可用 `home-axiom` cloudflared tunnel、age-encrypted tunnel credentials 和 loopback-only opencode pattern。
- `同 opencode` 指当前 wiki 真源里的 `opencode-axiom` Access 策略：Google IdP + exact emails `c1@ntnl.io`、`siyuan.arc@gmail.com`、`froggy2818@gmail.com`。
- 可使用现有 Cloudflare API credential 来源进行 DNS/Access 控制面配置；若不可用，记录 blocker 和精确人工步骤。
- 不需要在本任务中运行实体 `nixos-rebuild switch`。

## 约束

- 遵守 Legion workflow；稳定 contract 后进入 `git-worktree-pr` envelope。
- 不打印或提交 Cloudflare API token、cloudflared tunnel credential JSON、Access OIDC secret 或其他 secret。
- 不放宽 opencode 现有 Access 策略，也不修改 opencode 服务监听地址。
- 不创建新的 tunnel credential secret；复用 `axiom` 已有 cloudflared tunnel。
- 不新增 broad domain allow、everyone allow、bypass policy 或非 Google IdP。

## 风险

- **High**: 这是 Cloudflare Access / public hostname 权限边界变更；错误策略可能把 status page 暴露给非预期用户，或把 tunnel route 配到错误服务。
- Gatus 从 `acorn` 迁到 `axiom` 会改变运行主机；`acorn` 上的 Prometheus/Gatus 状态页不再是当前 public path。
- Cloudflare API 状态可能和 wiki 记录不完全一致，需要 reconcile 而不是盲建。
- DNS/Access 控制面变更可通过 API 验证，但交互式浏览器登录仍可能需要人工 smoke。

## 范围

- `hosts/axiom/default.nix` 中 Gatus enablement 和 cloudflared ingress。
- `hosts/acorn/default.nix` / `hosts/acorn/modules/status.nix` 中旧 status page 入口的移除或停用。
- `docs/gatus-status.md` 中 public URL、host、Cloudflare Access 和验证说明。
- Cloudflare DNS route / Access application / policy for `status-axiom.0xc1.space`，在凭证可用时通过 API/CLI 执行并验证。
- `.legion/tasks/gatus-axiom-cloudflare-access/**` 与 `.legion/wiki/**` evidence/writeback。

## 非目标

- 不重写 Gatus endpoint inventory 的业务语义，除非迁移到 `axiom` 所必需。
- 不引入 Terraform 或新的 Cloudflare IaC 框架。
- 不修改 `opencode-axiom.0xc1.space` Access allowlist 之外的策略。
- 不配置 alerting/incident workflow。
- 不执行生产主机切换部署。

## 设计概要

- **域名选择**: 使用 `status-axiom.0xc1.space`，与 `opencode-axiom.0xc1.space` 的 service-host 命名保持一致。
- **部署位置**: Gatus 迁到 `axiom` 本机，继续 loopback bind `127.0.0.1:8080`，让 cloudflared 和 Prometheus 都访问本机 loopback。
- **公开入口**: `home-axiom` tunnel 新增 status ingress；cloudflared 是 transport，不是 auth。
- **认证边界**: Cloudflare Access 使用和 `opencode-axiom` 一致的 Google IdP + exact-email allowlist，禁止 broad allow/bypass。
- **旧入口收敛**: 移除 `acorn` 的 `status.0xc1.space` nginx public route，避免两个公网 status page。

## 阶段概览

1. **Contract** - 固化域名、host、Access 策略、scope 和风险。
2. **Design** - 形成 RFC，覆盖 Cloudflare route/Access reconcile、rollback 和验证。
3. **Implementation** - 修改 Nix/docs 并执行 Cloudflare 控制面配置（凭证可用时）。
4. **Verification** - Nix eval/build + Cloudflare API/CLI assertions + secret hygiene checks。
5. **Delivery** - review、walkthrough、wiki、PR lifecycle 和 Linear 更新。

## 设计索引

> **Design Source of Truth**: `.legion/tasks/gatus-axiom-cloudflare-access/docs/rfc.md`

**摘要**:
- 核心路线: 选择 `status-axiom.0xc1.space`，把 Gatus 迁到 `axiom` 本机，并通过 `home-axiom` cloudflared ingress 暴露 loopback Gatus。
- Access: 创建/更新 `status-axiom.0xc1.space` self-hosted Access app，策略同当前 `opencode-axiom`：Google IdP + exact emails `c1@ntnl.io`、`siyuan.arc@gmail.com`、`froggy2818@gmail.com`。
- 验证策略: Nix build/eval 证明 repo config；Cloudflare API/CLI assertions 证明 DNS route 和 Access app/policy；浏览器登录作为人工 smoke。

---

*Created: 2026-05-17 | Updated: 2026-05-17*
