# Deploy 1Ex portfolio adapter on Acorn - 日志

## 会话进展 (2026-08-18)

### ✅ 已完成

- RFC and RFC review completed for the vendored source, age boundary, systemd/nginx/ACME design, and rollback path.
- The Acorn configuration, encrypted environment, and DNS-only Cloudflare A record were added within scope.
- The Acorn closure built locally; remote activation used the required local-build command and completed successfully.
- Direct SNI HTTPS validation proved the TLS boundary, unauthorized `401`, authenticated `200` accounts/positions responses, five positions, and a live valuation.
- Public recursive DNS now resolves to Acorn; an independent ordinary-hostname request reaches the expected `401` bearer boundary.
- A fresh upstream clone verified the tracked vendor files match the pinned `8dcf21f` source before the Nix timeout patch.
- Change review passed with no code or security blockers.

### 🟡 进行中

- Complete walkthrough, wiki, commit, PR, and merge lifecycle evidence.

### ⚠️ 阻塞/待定

- `auth.ntnl.io` and 1Ex occasionally fail transiently; the adapter correctly returns `502` rather than exposing a partial result. This is an operational residual, not an activation blocker.

---

## 关键文件

- `hosts/acorn/modules/oneex-portfolio-adapter.nix`: vendored Rust build, service hardening, nginx and ACME configuration.
- `hosts/acorn/secrets/oneex-portfolio-adapter-env.age`: encrypted runtime environment.
- `packages/oneex-portfolio-adapter/vendor/`: pinned upstream source snapshot.
- `docs/rfc.md`, `docs/test-report.md`, `docs/review-change.md`: design, evidence, and review artifacts.

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Track a pinned vendor snapshot in dotfiles | Private Git source fetch and submodule evaluation were not reliable in the pure flake build | Fetch source during evaluation | 2026-08-18 |
| Patch only `READ_TIMEOUT` to 5.8s | Live reads exceeded the upstream 4.5s budget while remaining below the ten-second source deadline | Change upstream code before deployment | 2026-08-18 |
| Retain the default `auth.ntnl.io` issuer | 1Ex rejected the locally minted auth-mini token | Loopback `AUTH_BASE_URL` override | 2026-08-18 |
| Create a DNS-only Cloudflare record | ACME and the public hostname require an externally resolvable A record | Cloudflare proxy or a different hostname | 2026-08-18 |

---

## 快速交接

**下次继续从这里开始：**

1. Produce the walkthrough and wiki entry, then run final diff/build checks.
2. Rebase on `origin/master`, commit, push, create the PR, and follow checks/review through merge and cleanup.

**注意事项：**

- subagent 不直接改写 .legion 三文件。
- Do not run Nix builds on Acorn. Use the exact remote switch command with `--build-host localhost`.
- Do not print or commit the bearer, identity seed, or decrypted environment values.

---

*最后更新: 2026-08-18*
