# Reviewer Walkthrough

**Mode:** implementation

## What changed

- Added an Acorn-only encrypted Resend API key artifact and recipient entry.
- Declared its deployed agenix file for `auth-mini:auth-mini` with mode `0400`.
- The repository PR adds the Acorn agenix retention/deployment declaration; application SMTP state remains in auth-mini's SQLite database.

## Evidence

- Acorn toplevel build and `git diff --check`: PASS.
- Secret decrypt-roundtrip matched; focused scanning found no plaintext key outside `.age` files.
- Application SMTP configuration already succeeded: live read-back showed Resend on port 465 with implicit TLS and sender `auth@0xc1.space`.
- Live OTP already succeeded: `/email/start` returned `200 {"ok":true}`, and Resend send history recorded the message.
- Security/readiness review: PASS with no blocking findings.

## Reviewer focus

- Confirm the new age recipient is Acorn-only.
- Confirm the runtime file remains owned by `auth-mini:auth-mini` with mode `0400`.
- After merge and Acorn switch, verify `/run/agenix/auth-mini-resend-api-key`; no repeat OTP is required unless SMTP state changes.

## Residual risk

SMTP configuration is not reconciled from the retained secret. Database recovery or key rotation requires another authenticated admin API update.
