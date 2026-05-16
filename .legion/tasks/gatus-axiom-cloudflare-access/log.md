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

### 进行中

- 进入 delivery 阶段，准备做 blocked change review、walkthrough、wiki writeback 和 PR lifecycle。

### 阻塞/待定

- Cloudflare Access 控制面配置被 credential 权限阻塞：`hosts/charlie/secrets/cloudflare-api-token.age` 可读 DNS/zone，但 `GET /accounts/<account-id>/access/identity_providers` 返回 403。
- 用户授权尝试 `/home/c1/dotfiles/token.env`，但当前 filesystem 未找到该文件，`API_TOKEN` / `CLOUDFLARE_API_TOKEN` / `CF_API_TOKEN` 环境变量也不存在。
- 用户要求尝试解密 `axiom` 的 age credential；该文件不是当前用户 key 加密，非交互 `sudo` 读取 `/etc/ssh/ssh_host_ed25519_key` 需要密码，无法继续。即便可解密，cloudflared credential JSON 也不是 Cloudflare Zero Trust Access API token，不能创建 Access app/policy。
- 因 Access app/policy 无法配置/验证，未创建 `status-axiom.0xc1.space` DNS/tunnel route，避免部署后出现无 Access 边界的 public surface。
- 交互式 Google 登录 smoke 无法保证自动完成，可能作为部署后人工验证。

---

## Git Envelope

- **base ref**: `origin/master` at `bca89ddd5e6f48d4dafad663388c69d1854c8e2f`
- **branch**: `legion/gatus-axiom-cloudflare-access-route`
- **worktree path**: `.worktrees/gatus-axiom-cloudflare-access`
- **PR URL/state**: not created yet
- **checks/review state**: not started
- **cleanup state**: pending
- **main refresh state**: pending

---

## 快速交接

1. Repo 变更和本地 Nix 验证已完成。
2. Cloudflare Access 控制面被凭证权限阻塞；需要 Access-capable token 或人工 dashboard/API 操作。
3. 恢复条件：提供可访问 Zero Trust Access apps/policies 的 token 后，先创建/验证 Access app/policy，再创建 DNS CNAME route。

---

*Updated: 2026-05-17*
