# Gatus Axiom Cloudflare Access - 日志

## 会话进展 (2026-05-17)

### 已完成

- 用户要求把 Gatus 对外入口改为 `status.axiom.0xc1.space` 或 `status-axiom.0xc1.space` 二选一，并配置 cloudflared 和 Cloudflare Access，Access 同 opencode。
- 读取当前 Gatus 任务、wiki 和 host 配置，确认上一版 Gatus 在 `acorn`，公网入口是 `status.0xc1.space` 的 nginx/ACME vhost。
- 读取 `axiom` cloudflared 配置和 opencode Access wiki 真源，确认 `opencode-axiom.0xc1.space` 走 `home-axiom` tunnel，Access 使用 Google IdP 和 exact-email allowlist。
- 选择 `status-axiom.0xc1.space`，原因是与现有 `opencode-axiom.0xc1.space` service-host 命名一致，避免新增 `axiom.0xc1.space` 子域层级。
- 建立新任务契约，范围是把 Gatus public surface 从 `acorn` nginx 迁到 `axiom` cloudflared + Cloudflare Access。
- 按 git-worktree-pr envelope 从 `origin/master` 创建 `.worktrees/gatus-axiom-cloudflare-access`，分支 `legion/gatus-axiom-cloudflare-access-route`。
- 生成 `docs/research.md` 与 High-risk RFC，覆盖 repo migration、Cloudflare DNS route、Access app/policy、rollback 和 verification。
- 完成 `docs/review-rfc.md`，结论 PASS。
- 已在 worktree 中实现 repo 变更：`axiom` 启用 Gatus/Prometheus，`home-axiom` tunnel 添加 `status-axiom.0xc1.space -> http://127.0.0.1:8080`，`acorn` 移除旧 status module import 并删除旧 `status.0xc1.space` module，runbook 更新为 axiom/cloudflared/Access 模式。
- 本地验证通过：`nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`、Gatus loopback bind eval、metrics eval、cloudflared ingress eval、Prometheus scrape eval、`acorn` old vhost absence eval 和 `git diff --check`。
- Cloudflare DNS 读取验证通过：`status-axiom.0xc1.space` 当前无 DNS record，`opencode-axiom.0xc1.space` CNAME 指向 `bc8b3291-de93-4f7f-807a-23f802ef021f.cfargotunnel.com` 且 proxied，`status.0xc1.space` 当前无 DNS record。
- 完成 `docs/test-report.md`、`docs/review-change.md`、`docs/report-walkthrough.md`、`docs/pr-body.md` 和 wiki writeback。
- 已创建 draft PR: https://github.com/Thrimbda/dotfiles/pull/65。
- auto-merge 尝试结果：GitHub 拒绝，原因是 PR 仍是 draft。`gh pr checks 65 --required` 当前报告 no checks。
- 已在 Linear `0XC-7` 添加 blocked handoff 评论，comment id `cef48775-f4c8-47f2-94df-eb60c3b9b88f`。
- 已在 Linear `0XC-7` 添加 axiom credential inspection 更正评论，comment id `d0abbfe9-44fa-426d-a015-375ff3848f34`。
- 用户写入 `/home/c1/dotfiles/API_TOKEN.env` 后，验证 token 成功：zone read、Access identity providers、Access apps 和 Access policies 均返回 200。
- 已创建并验证 `status-axiom.0xc1.space` Cloudflare Access app `c73a8ab9-990b-41f2-bc03-41370769a69b`，Google IdP `399adc69-d770-4685-8acf-cdea3acca230`，`auto_redirect_to_identity = true`，`session_duration = 24h`。
- 已创建并验证 allow policy `e20cae5a-a2de-4877-9fa0-285210ca76d1`，exact emails `c1@ntnl.io`、`siyuan.arc@gmail.com`、`froggy2818@gmail.com`，require Google login，无 broad/bypass policy。
- Access 验证通过后，已创建 proxied CNAME `status-axiom.0xc1.space -> bc8b3291-de93-4f7f-807a-23f802ef021f.cfargotunnel.com`，DNS record id `c7c261f01c4deeb89258b2d3941bb3a5`。

### 进行中

- 更新 PR evidence，准备将 draft PR 转为 ready 并重新尝试 auto-merge。

### 阻塞/待定

- `hosts/charlie/secrets/cloudflare-api-token.age` 仍只可读 DNS/zone，`GET /accounts/<account-id>/access/identity_providers` 返回 403；本次 Cloudflare Access/DNS 使用的是用户提供的本地 `/home/c1/dotfiles/API_TOKEN.env`。
- `/home/c1/dotfiles/API_TOKEN.env` 是本地明文 secret，不提交到 repo；后续应删除、移出 repo 或纳入 age 管理。
- 用户随后把 `axiom` host key 放到 repo 根目录；已用该 key 解密 `hosts/axiom/secrets/cloudflared-credentials.age`，确认内容只有 cloudflared runtime JSON 字段 `AccountTag`、`Endpoint`、`TunnelID`、`TunnelSecret`，没有 `API_TOKEN` / `CLOUDFLARE_API_TOKEN` / `CF_API_TOKEN` 等 API token 字段。
- 已将 `hosts/axiom/secrets/cloudflared-credentials.age` 重新加密到 axiom host key 和 `/home/c1/.ssh/id_ed25519.pub` 两个 recipient；验证 user key 可解密且 `TunnelID` 匹配。
- 交互式 Google 登录 smoke 和生产 `axiom` deploy 未执行，作为部署后人工验证。

---

## Git Envelope

- **base ref**: `origin/master` at `bca89ddd5e6f48d4dafad663388c69d1854c8e2f`
- **branch**: `legion/gatus-axiom-cloudflare-access-route`
- **worktree path**: `.worktrees/gatus-axiom-cloudflare-access`
- **PR URL/state**: https://github.com/Thrimbda/dotfiles/pull/65 / OPEN draft
- **checks/review state**: no required checks reported before ready-for-review; review not started; auto-merge pending retry after evidence update; Linear updated twice
- **cleanup state**: pending
- **main refresh state**: pending

---

## 快速交接

1. Repo 变更、本地 Nix 验证、Cloudflare Access app/policy 和 DNS CNAME 已完成。
2. 待完成：更新 PR evidence、ready-for-review、auto-merge/checks/review follow-up。
3. 部署后人工验证：`systemctl status gatus cloudflared prometheus`、allowed/denied Google Access login、Prometheus scrape。

---

*Updated: 2026-06-01*
