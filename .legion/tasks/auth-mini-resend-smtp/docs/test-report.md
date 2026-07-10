# Test Report

## Result

PASS.

## Secret Validation

- Root input `resent_key` was checked without printing it: non-empty, 37 bytes, raw `re_...` shape.
- Encrypted output: `hosts/acorn/secrets/auth-mini-resend-api-key.age`.
- Decrypt-roundtrip SHA-256 matched the source using the authorized local identity; neither value nor hash is recorded here.
- Focused `git grep` found no Resend key pattern outside `.age` files.
- The plaintext root input remains untracked and outside the worktree.

Evaluated secret configuration:

```json
{
  "group": "auth-mini",
  "mode": "0400",
  "owner": "auth-mini",
  "path": "/run/agenix/auth-mini-resend-api-key"
}
```

## Nix Validation

Command:

```sh
nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel
```

Result: PASS.

Command:

```sh
git diff --check
```

Result: PASS.

## Live Configuration

The Resend key was streamed over stdin to an authenticated Acorn loopback admin API client. It was not placed in argv, environment output, or logs. The client preserved issuer, RP ID, and branding, replaced SMTP config, and logged out its temporary admin session.

Read-back summary:

```text
smtp_host= smtp.resend.com
smtp_port= 465
smtp_username= resend
smtp_from= auth@0xc1.space
smtp_secure= True
smtp_active= True
```

Acorn TCP smoke:

```text
smtp.resend.com:465 -> reachable
```

## Live OTP

Request:

```http
POST http://127.0.0.1:7777/email/start
Content-Type: application/json

{"email":"<existing-admin-email>"}
```

Response:

```http
HTTP/1.1 200 OK

{"ok":true}
```

Resend API send history confirmed a new message:

- From: `auth-mini <auth@0xc1.space>`
- To: existing admin email
- Subject: `Your auth-mini verification code`
- Created: `2026-07-10 08:59:26 UTC`

No OTP value, API key, access token, refresh token, or SMTP password was recorded.

## Pending Deployment Check

The application SMTP state is already live. After the repo change is merged and Acorn is switched, verify `/run/agenix/auth-mini-resend-api-key` exists with `auth-mini:auth-mini` ownership and mode `0400`. No second OTP send is required unless the live configuration changes.
