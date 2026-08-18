# 部署 Legion Pi Web 并通过 Acorn FRP 安全暴露 - 日志

## 会话进展 (2026-08-18)

### ✅ 已完成

- 用户确认使用 https://pi-axiom.0xc1.wang 与现有 Auth Mini；PI WEB 1.202608.1、Pi core 0.84.2、FRP 0.66.0 和现有 Axiom/Acorn 配置已复核。
- 首轮独立 review-rfc-jolly-penguin 返回 FAIL：共享 FRPS 的 proxyBindAddr 为全局配置，单个 18082 不能独立 loopback bind。
- RFC 已改为共享 FRPS wildcard-bound + Acorn firewall deny + nginx loopback consumption，并补齐 c1 operator 与 active daemon process-env 证据。
- 用户明确要求部署任务不使用 Heavy RFC；已删除 Heavy research/implementation-plan 和基于旧稿的 review artifact，收敛为单一 Standard RFC。
- Standard RFC 经独立 review-rfc-lively-capybara 审查，无 blocking finding，Verdict PASS。
- Axiom linger/login env/Auth Mini gateway/FRP proxy 与 Acorn cert/vhost/firewall 断言已按批准 Standard RFC 实现。
- 首轮 targeted nix eval 与 git diff --check 通过；Acorn firewall allowlist 未包含 18082。
- Legion Pi 首装 copied=3、幂等复跑 skipped=3、verify READY；PI 0.84.2。
- @jmfederico/pi-web@1.202608.1 与 node-pty 安装成功，upstream user units active，doctor 全绿。
- Axiom 目标 generation 1y5yz2p09prf 生效：Linger=yes，8504/7782 loopback-only，active daemon exact-name env 与 canonical profile 一致，四个 FRP proxy success。
- Acorn 由 Axiom 按规定命令构建/传输/激活；最终 generation `nhpsfnjkmzcn7chrqvh8jg7ll5jrcmsi`，未在 Acorn 构建。
- 使用现有 Acorn Cloudflare token 一次性创建 pi-axiom.0xc1.wang DNS-only A record；bootstrap 已移除并重部署最终干净配置。
- Cloudflare DoH 返回 8.159.128.125；HTTPS SAN 有效并返回 Auth Mini 302；18082 公网连接超时，status/opencode/1Ex 无回退。
- 部署期间发现 worktree 基线落后于已合并的 1Ex 配置；已 rebase 到最新 `origin/master` 并重新部署集成 generation，恢复且验证 1Ex 后继续。
- 首次浏览器空白由 Acorn nginx 尚未加载新 PI vhost 和 Zen 常规 profile 缓存旧响应共同造成；重新激活 nginx 后，Zen 隐私窗口完成 Auth Mini 登录、callback、PI 页面和会话验收。
- 初轮 `review-change-cheery-heron` 发现 cookie-authenticated WebSocket 缺少 exact Origin 边界并返回 FAIL；Standard RFC 已补充 foreign/missing Origin fail-closed 设计，`review-rfc-brisk-marten` 复审 PASS。
- Acorn nginx PI vhost 已部署 exact-Origin guard：sibling/foreign/missing Origin upgrade 返回 403，exact PI Origin 通过；普通 HTTP/API 和 status/opencode 不受影响。
- 最终 `verify-change-merry-badger` 与 `review-change-cheery-lynx` 均返回 PASS，无未解决安全 blocker；walkthrough 与 Wiki writeback 已完成。

(暂无)
### 🟡 进行中

- 提交最终变更并完成 PR checks/review/merge/cleanup lifecycle。
### ⚠️ 阻塞/待定

- 约束: Acorn 构建与部署只能从 Axiom 使用仓库规定的远程 nixos-rebuild 命令，禁止在 Acorn 本机构建。

(暂无)
---

## 关键文件

(暂无)
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Cloudflare DNS A record 作为 live deployment state 一次性创建，不把 DNS reconciler 留在最终 Nix 配置 | 仓库现有 public hostname 采用 live DNS-only records；永久 boot-time API reconciler 会扩大部署任务和 secret failure surface。 | 永久 Nix systemd DNS reconciler；要求用户手工创建；缺 DNS 仍交付。 | 2026-08-18 |
---

## 快速交接

**下次继续从这里开始：**

1. 提交当前最终 diff。
2. 创建 PR 并跟进 checks/review 到 terminal state。
3. 清理 worktree，并安全刷新 dotfiles 主工作区。

**注意事项：**

- 最终 tracked diff 不含一次性 DNS bootstrap 或任何 secret。
---

*最后更新: 2026-08-19 by Legion CLI*
