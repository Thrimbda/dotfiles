# Change Review

Mode: implementation.

## Result

PASS. No blocking findings.

## Review Scope

- Dotfiles production diff: advance `packages/auth-mini-gateway/default.nix` to the reviewed upstream merge commit and remove the obsolete `REQUIRE_PASSKEY` entry from `hosts/acorn/secrets/auth-mini-gateway-env.age`.
- Upstream auth-mini-gateway PR [#4](https://github.com/Thrimbda/auth-mini-gateway/pull/4), merged as `f0519d1fcfbf49be43602f7a25ad2373434366fe`.
- Task contract, implementation handoff in `log.md`, and `docs/test-report.md`.

## Findings

No correctness, maintainability, scope, or security blocker was found.

- The package pin targets only the reviewed upstream policy-removal commit.
- The encrypted environment change removes the obsolete method-policy setting. Sanitized decrypted-env evidence confirms `ALLOW_EMAILS` and `ALLOW_USER_IDS` remain present with their exact existing identity values; no identity is added, removed, or broadened. Plaintext allowlists remain intentionally omitted from review artifacts.
- Authorization remains deny-by-default: a verified auth-mini identity must exactly match `ALLOW_EMAILS` or `ALLOW_USER_IDS`. Unknown identities remain denied before upstream access.
- Unauthenticated redirect handling, verified token/session binding, opaque gateway sessions, host-only cookies, refresh/logout, nginx `auth_request`, per-origin gateway instances, and loopback-only backend boundaries are unchanged.

## Security Lens

Applied because this change affects authentication and authorization.

The trust boundary is narrowed to the intended split: auth-mini decides how a user authenticates; auth-mini-gateway verifies the resulting auth-mini session and authorizes only exact allowlisted identity. Removing gateway `amr=webauthn` enforcement does not bypass identity policy or expose a protected upstream. Upstream PR #4's security/readiness review also passed with no blockers.

## Evidence Assessed

- Upstream: `cargo fmt --check`; all 11 `cargo test` tests; real auth-mini + nginx E2E for Email OTP callback, HTTP/WebSocket proxying, persistence, refresh/logout, refresh-failure revocation, and unknown-user denial.
- Dotfiles: gateway package build; Acorn toplevel build; all four gateway `ExecStart` values resolve to the updated binary; built binary lacks `REQUIRE_PASSKEY`; sanitized decrypted env has only `ALLOW_EMAILS`, `ALLOW_USER_IDS`, and `GATEWAY_COOKIE_SECRET`; `git diff --check` passes.

## Residual Risk

The repository and integration evidence is complete, but the merged generation has not yet been switched on Acorn because remote sudo is interactive. A post-switch browser smoke must confirm the live Email OTP callback and all three protected origins. This is a deployment follow-up, not a review blocker.
