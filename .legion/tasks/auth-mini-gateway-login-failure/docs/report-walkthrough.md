# Reviewer Walkthrough

Mode: implementation.

## Summary

This change fixes the auth-mini gateway's generic `Login failed. Please try again.` result for an allowlisted Email OTP session. It deploys the upstream removal of gateway-owned authentication-method policy while preserving the exact email/user-id allowlists and every existing proxy, cookie, and network boundary.

## Root Cause

The user was authenticated and allowlisted, but the two recent auth-mini sessions used `email_otp`; no session used `webauthn`. The deployed gateway had `REQUIRE_PASSKEY=true`, so its policy returned `403` despite the valid identity. The callback bridge maps every non-2xx `/auth/callback/session` response to the same generic failure text, hiding that policy decision.

## Exact Behavioral Change

| Before | After |
| --- | --- |
| A verified auth-mini session needed an exact `ALLOW_EMAILS`/`ALLOW_USER_IDS` match **and**, with `REQUIRE_PASSKEY=true`, `amr=webauthn`. | A verified auth-mini session needs only an exact `ALLOW_EMAILS` or `ALLOW_USER_IDS` match; the authentication method no longer affects gateway authorization. |
| An allowlisted Email OTP session received `403` and the browser showed the generic login failure. | The same allowlisted Email OTP session can create an opaque gateway session and reach the protected upstream. |
| Unknown identities were denied. | Unknown identities are still denied before upstream access. |

Auth-mini remains the authority for authentication methods. The gateway still verifies auth-mini token/session identity and applies deny-by-default identity authorization.

## Delivered Changes

- Upstream auth-mini-gateway PR [#4](https://github.com/Thrimbda/auth-mini-gateway/pull/4), `refactor: remove authentication method policy`, merged at `f0519d1fcfbf49be43602f7a25ad2373434366fe`.
- Dotfiles pins `auth-mini-gateway` to that exact commit and updated source hash.
- Acorn's encrypted gateway environment removes only the obsolete `REQUIRE_PASSKEY` setting.
- The exact existing `ALLOW_EMAILS` and `ALLOW_USER_IDS` identity values are preserved—no identity is added, removed, or broadened. Their plaintext values are intentionally not reproduced in this artifact.

## Preserved Boundaries

- Unauthenticated requests still redirect to auth-mini with the correct per-origin callback and state.
- Exact email/user-id allowlists remain mandatory; non-allowlisted sessions remain `403`.
- JWT/session verification, opaque host-only gateway cookies, refresh/logout, and nginx `auth_request` remain in place.
- The separate gateway instances and protected-origin set are unchanged: `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang`.
- Auth mini, the gateway vhost, Vaultwarden, and backend ports remain outside the protected-upstream expansion; ports `7777`-`7781` remain loopback-only.

## Validation

- Upstream `cargo fmt --check`: PASS.
- Upstream `cargo test`: PASS, all 11 tests.
- Real auth-mini + nginx E2E: PASS for Email OTP callback, protected HTTP, authenticated WebSocket, SQLite session persistence, refresh/logout, refresh-failure revocation, and unknown-user denial.
- Dotfiles gateway package build: PASS at `/nix/store/f9hajhs6v1ksrvx64a83q435qvzbb4rg-auth-mini-gateway-0.1.0-unstable-2026-07-10`.
- Acorn toplevel build: PASS; all four gateway `ExecStart` values use the updated binary.
- Artifact/env inspection: PASS; the binary has no `REQUIRE_PASSKEY`, and the sanitized env contains only `ALLOW_EMAILS`, `ALLOW_USER_IDS`, and `GATEWAY_COOKIE_SECRET`.
- `git diff --check`: PASS.

## Review Verdict

PASS with no blocking findings. The security lens found that the change removes only the redundant authentication-method restriction; exact identity authorization and the existing trust boundaries remain enforced.

## Deployment Procedure

After this dotfiles PR is merged, use a clean checkout of the merged branch and run from the repository root:

```bash
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --use-remote-sudo --fast --use-substitutes
```

Remote sudo requires an interactive terminal. After the switch, explicitly restart all gateway instances and confirm they are active:

```bash
ssh -t c1@8.159.128.125 'sudo systemctl restart auth-mini-gateway-auth-gateway.service auth-mini-gateway-status-axiom.service auth-mini-gateway-opencode-axiom.service auth-mini-gateway-frps-acorn.service && systemctl is-active auth-mini-gateway-auth-gateway.service auth-mini-gateway-status-axiom.service auth-mini-gateway-opencode-axiom.service auth-mini-gateway-frps-acorn.service'
```

Do not log decrypted environment values, OTPs, tokens, cookies, or refresh credentials during deployment.

## Residual Post-Switch Browser Smoke

The only remaining evidence is live behavior after the merged generation is switched:

1. In a fresh browser context, open each protected origin and confirm unauthenticated requests redirect to auth-mini with the matching origin callback.
2. Log in as the existing allowlisted user with Email OTP and confirm successful return plus access to status, opencode, and the frps dashboard.
3. Confirm opencode's authenticated WebSocket path works and the browser receives only an opaque, host-only gateway session cookie.
4. Confirm a non-allowlisted auth-mini identity is denied and does not reach an upstream.
5. Exercise logout and confirm protected access requires authentication again.

Until that smoke passes, the implementation is review-ready but not yet proven in the live switched environment.
