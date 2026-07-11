## Summary

- Deploy upstream auth-mini-gateway PR [#4](https://github.com/Thrimbda/auth-mini-gateway/pull/4) at `f0519d1fcfbf49be43602f7a25ad2373434366fe`.
- Remove gateway-owned Passkey/`amr` authorization so a verified auth-mini session is authorized solely by exact email/user-id allowlists.
- Remove the obsolete `REQUIRE_PASSKEY` secret entry without adding, removing, or broadening any `ALLOW_EMAILS` or `ALLOW_USER_IDS` identity.

## Root Cause and Behavior

The failing user was authenticated and allowlisted, but the active auth-mini session used Email OTP. `REQUIRE_PASSKEY=true` made the gateway return `403`, which the callback bridge rendered as generic `Login failed. Please try again.` After this change, that allowlisted Email OTP session can create an opaque gateway session and reach the upstream. Unauthenticated redirects and unknown-identity denial are unchanged.

## Validation

- Upstream `cargo fmt --check` and all 11 `cargo test` tests
- Real auth-mini + nginx E2E: Email OTP callback, HTTP/WebSocket, persistence, refresh/logout, refresh-failure revocation, unknown-user denial
- Dotfiles gateway package build and Acorn toplevel build
- All four gateway `ExecStart` values resolve to the updated binary
- Built binary has no `REQUIRE_PASSKEY`; sanitized env contains only the two identity allowlists and cookie secret
- `git diff --check`
- Security/readiness review: **PASS**, no blockers

## Deployment / Residual

After merge, switch Acorn with interactive remote sudo:

```bash
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --use-remote-sudo --fast --use-substitutes
```

Then restart the four `auth-mini-gateway-*` instances and browser-smoke Email OTP access to status, opencode (including WebSocket), and the frps dashboard; also confirm unauthenticated redirect, non-allowlisted denial, and logout. This post-switch live smoke remains pending.
