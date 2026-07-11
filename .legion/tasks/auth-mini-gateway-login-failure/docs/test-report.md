# Test Report

## Result

Implementation verification passed. Live browser smoke remains pending until the dotfiles PR is merged and the Acorn host can be switched with interactive `sudo`.

## Evidence

- Upstream auth-mini-gateway PR #4 merged at `f0519d1fcfbf49be43602f7a25ad2373434366fe`.
- `cargo fmt --check` passed.
- `cargo test` passed all 11 tests.
- Real Docker auth-mini + nginx E2E passed Email OTP callback, HTTP and WebSocket proxying, session persistence, refresh and logout, refresh-failure revocation, and unknown-user denial.
- The dotfiles package build passed at `/nix/store/f9hajhs6v1ksrvx64a83q435qvzbb4rg-auth-mini-gateway-0.1.0-unstable-2026-07-10`.
- The Acorn toplevel build passed; all four gateway `ExecStart` values point to the updated binary.
- The built binary does not contain `REQUIRE_PASSKEY`.
- Sanitized decrypted-env inspection found only `ALLOW_EMAILS`, `ALLOW_USER_IDS`, and `GATEWAY_COOKIE_SECRET`; the four-email allowlist includes `siyuan.arc@gmail.com`, and `REQUIRE_PASSKEY` is absent.
- `git diff --check` passed.

## Pending

- Merge the dotfiles PR, perform the interactive-sudo Acorn switch, and run the live browser smoke across the protected origins.
