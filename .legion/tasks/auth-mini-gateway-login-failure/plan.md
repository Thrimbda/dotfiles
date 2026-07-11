# Auth Mini Gateway Login Failure

## Goal

Remove authentication-method policy from auth-mini-gateway so any auth-mini-authenticated session can pass when its identity matches the configured email/user-id allowlist.

## Problem

Unauthenticated requests correctly redirect to auth-mini, but the gateway bridge reports `Login failed. Please try again.` Diagnosis proved the target user has one Passkey credential but the two recent sessions are `email_otp`, with no `webauthn` session. The gateway returns `403` because `REQUIRE_PASSKEY=true`, while its callback bridge misleadingly maps every non-2xx response to the generic login-failed message. The user explicitly rejected gateway-level authentication-method policy: auth-mini is the IdP, and gateway authorization should depend on authenticated identity allowlists rather than `amr`.

## Scope

- Remove `REQUIRE_PASSKEY` configuration and Passkey/`amr` enforcement from upstream auth-mini-gateway.
- Update upstream tests and documentation to describe identity-only authorization.
- Update the dotfiles package pin and remove the obsolete env key from the encrypted Acorn gateway environment.
- Restart the gateway instances after deployment and verify Email OTP policy behavior.
- Verify all three protected origins: status, opencode, and frps dashboard.

## Non-Goals

- Do not broaden or otherwise alter the email/user-id allowlists.
- Do not add Vaultwarden, auth-mini, or auth-gateway itself to the protected upstream set.
- Do not redesign per-origin gateway instances or host-only cookies unless the evidence proves that model is the cause.
- Do not expose tokens, cookies, refresh credentials, or gateway secrets in logs/docs.

## Acceptance Criteria

- The generic error is tied to the concrete `403` Passkey-policy decision.
- `siyuan.arc@gmail.com` with any valid auth-mini session is allowed by gateway policy and receives an opaque gateway session cookie.
- Authenticated requests reach each protected upstream.
- Unauthenticated requests still redirect and non-allowlisted sessions remain denied.
- Acorn toplevel build and relevant gateway tests pass.

## Assumptions

- Live allowlist contains that email; safe inspection confirmed it.
- All three gateway services are active and unauthenticated requests currently redirect to auth-mini.

## Constraints

- Preserve the current auth and secret boundaries.
- Keep backend and gateway ports loopback-only.
- Use sanitized diagnostics; never print complete tokens or session cookies.

## Risks

- Callback bugs cross browser fragment handling, nginx, gateway state, and auth-mini token semantics.
- Removing the wrong policy condition could accidentally bypass identity allowlists; tests must prove unknown users remain denied.
- A package pin update can carry unrelated upstream changes; pin only the reviewed policy-removal commit.

## Recommended Direction

Remove authentication-method enforcement from upstream gateway policy while preserving exact email/user-id allowlists. Remove the obsolete Acorn env key, pin the reviewed upstream commit, and verify allowed Email OTP plus denied unknown identity behavior.

## Phases

1. Record the diagnosed policy rejection.
2. Remove the upstream authentication-method policy and update tests/docs.
3. Update the dotfiles pin and encrypted env.
4. Verify allowlist invariants, builds, and policy behavior.
5. Deliver both PRs and run live smoke.
