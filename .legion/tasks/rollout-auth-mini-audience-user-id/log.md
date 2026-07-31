# Rollout Audience-Bound Gateway User IDs - 日志

## 会话进展 (2026-07-31)

### ✅ 已完成

- Created the rollout contract and confirmed all four gateway instances are in scope.
- Updated the gateway package pin to merged upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`.
- Migrated Axiom and Acorn encrypted gateway environments to the supplied exact user ID while preserving cookie secrets and removing `ALLOW_EMAILS`.
- Built the pinned gateway package and ran 119 library plus 50 proxy integration tests successfully.
- Merged configuration PR #157 as `8872e1f81947cc5fde20891e013d162d3e8a64ea`.
- Ran the first Axiom switch; activation exposed sanitized `upstream_protocol_cleartext_auto` failures on both gateway units.
- Added explicit `UPSTREAM_PROTOCOL=http1`, verified both unit evaluations and the Axiom toplevel build, and merged PR #158 as `fb78aea6a97e3a2b388972cbdfbcf540ed8cfcc2`.
- Reran Axiom switch successfully for both gateways; the remaining nonzero switch status came only from unrelated `rustdesk-provision.service` reporting `attempt-used`.
- Deployed Acorn from Axiom with the mandated `--build-host localhost --sudo --ask-sudo-password` command; no Nix build or rebuild ran on Acorn.
- Verified all four services are active on the new package, runtime env ownership/mode/content, local health checks, local login redirects, and public login redirects.

### 🟡 进行中

- Closeout documentation PR and final main-workspace refresh.

### ⚠️ 阻塞/待定

- Credential-bearing browser login smoke remains with the user after this closeout.

---

## 关键文件

- **`packages/auth-mini-gateway/default.nix`** [merged]
  - 作用: Pins the audience-bound gateway package.
  - 备注: Build and upstream tests passed.
- **`hosts/axiom/default.nix`** [merged]
  - 作用: Declares Axiom status/opencode gateway units.
  - 备注: Explicit `UPSTREAM_PROTOCOL=http1` is required for cleartext proxy mode.
- **`hosts/axiom/secrets/auth-mini-gateway-env.age`** [deployed]
  - 作用: Axiom gateway cookie secret and exact user-ID allowlist.
  - 备注: Runtime assertion passed without printing plaintext.
- **`hosts/acorn/secrets/auth-mini-gateway-env.age`** [deployed]
  - 作用: Acorn gateway cookie secret and exact user-ID allowlist.
  - 备注: Runtime assertion passed without printing plaintext.
- **`.legion/tasks/rollout-auth-mini-audience-user-id/docs/test-report.md`** [verified]
  - 作用: Repository and live deployment evidence.
  - 备注: Records the unrelated RustDesk provision failure separately.

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Migrate all four gateways together | Axiom and Acorn share the package pin and current auth-mini audience contract | Deploy only Axiom and leave Acorn broken on its next switch | 2026-07-31 |
| Preserve existing cookie secrets | The rollout does not need to invalidate existing browser cookies | Rotate secrets during the same production change | 2026-07-31 |
| Use exact user-ID-only authorization | Current downstream JWTs contain no email and cannot call self-audience `/me` | Keep email allowlists or infer legacy profiles | 2026-07-31 |
| Set Axiom proxy protocol to `http1` | New gateway startup refuses cleartext `UPSTREAM_URL` with implicit `auto` | Keep implicit auto and restart-loop | 2026-07-31 |
| Keep browser login smoke with the user | Production auth-mini data and credentials must not be modified for automation | Seed OTP/session state into auth-mini | 2026-07-31 |

---

## 快速交接

**下次继续从这里开始：**

1. Merge the closeout documentation PR and refresh the dotfiles main workspace.
2. Ask the user to complete one fresh browser login for `opencode-axiom.0xc1.wang` and, if desired, spot-check `status-axiom.0xc1.wang` and `frps-acorn.0xc1.wang`.

**注意事项：**

- Never print the supplied user ID, cookie secrets, tokens, callback bodies, or plaintext env contents.
- Do not run any Nix build or `nixos-rebuild` on Acorn.
- `rustdesk-provision.service` reports `attempt-used`; track it separately from this gateway rollout.

---

*最后更新: 2026-07-31 14:58*
