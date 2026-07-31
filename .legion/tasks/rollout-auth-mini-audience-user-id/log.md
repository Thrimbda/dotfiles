# Rollout Audience-Bound Gateway User IDs - 日志

## 会话进展 (2026-07-31)

### ✅ 已完成

- Created the rollout contract and confirmed all four gateway instances are in scope.
- Updated the gateway package pin to merged upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`.
- Migrated Axiom and Acorn encrypted gateway environments to the supplied exact user ID while preserving cookie secrets and removing `ALLOW_EMAILS`.
- Built the pinned gateway package and ran 119 library plus 50 proxy integration tests successfully.
- Merged configuration PR #157 as `8872e1f81947cc5fde20891e013d162d3e8a64ea`.
- Ran the first Axiom switch; activation exposed sanitized `upstream_protocol_cleartext_auto` failures on both gateway units.
- Added explicit `UPSTREAM_PROTOCOL=http1` for Axiom cleartext proxy gateways and verified both unit evaluations plus the Axiom toplevel build.

### 🟡 进行中

- Merge the protocol fix, refresh main, rerun Axiom switch, then deploy Acorn through the mandated Axiom build-host path.

### ⚠️ 阻塞/待定

- Credential-bearing browser login smoke remains with the user after services are healthy.

---

## 关键文件

- **`packages/auth-mini-gateway/default.nix`** [merged]
  - 作用: Pins the audience-bound gateway package.
  - 备注: Build and upstream tests passed.
- **`hosts/axiom/default.nix`** [fixed]
  - 作用: Declares Axiom status/opencode gateway units.
  - 备注: Explicit `UPSTREAM_PROTOCOL=http1` is required for cleartext proxy mode.
- **`hosts/axiom/secrets/auth-mini-gateway-env.age`** [merged]
  - 作用: Axiom gateway cookie secret and exact user-ID allowlist.
  - 备注: Re-encrypted for Axiom; plaintext was never printed or committed.
- **`hosts/acorn/secrets/auth-mini-gateway-env.age`** [merged]
  - 作用: Acorn gateway cookie secret and exact user-ID allowlist.
  - 备注: Re-encrypted for Acorn; plaintext was never printed or committed.

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Migrate all four gateways together | Axiom and Acorn share the package pin and current auth-mini audience contract | Deploy only Axiom and leave Acorn broken on its next switch | 2026-07-31 |
| Preserve existing cookie secrets | The rollout does not need to invalidate existing browser cookies | Rotate secrets during the same production change | 2026-07-31 |
| Use exact user-ID-only authorization | Current downstream JWTs contain no email and cannot call self-audience `/me` | Keep email allowlists or infer legacy profiles | 2026-07-31 |
| Set Axiom proxy protocol to `http1` | New gateway startup refuses cleartext `UPSTREAM_URL` with implicit `auto` | Keep implicit auto and restart-loop | 2026-07-31 |

---

## 快速交接

**下次继续从这里开始：**

1. Merge the protocol fix and refresh the dotfiles main workspace.
2. Rerun `sudo nixos-rebuild switch --flake .#axiom` and verify both Axiom gateways.
3. Run the mandated Acorn build-host switch and verify both Acorn gateways.

**注意事项：**

- Never print the supplied user ID, cookie secrets, tokens, callback bodies, or plaintext env contents.
- Do not run any Nix build or `nixos-rebuild` on Acorn.
- `rustdesk-provision.service` also reported a pre-existing `attempt-used` failure during Axiom activation; it is outside this task and did not affect gateway verification.

---

*最后更新: 2026-07-31 14:45*
