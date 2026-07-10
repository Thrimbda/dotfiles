# Auth Mini Resend SMTP

## Goal

Configure Acorn auth-mini to send email OTPs through Resend SMTP using an agenix-managed API key, then prove a real OTP request is accepted by the SMTP provider.

## Problem

The current Gmail SMTP configuration returns `smtp_temporarily_unavailable`. The user supplied a Resend API key in the repository root as plaintext operator input. Auth-mini persists SMTP configuration in SQLite and does not accept SMTP environment variables at process startup. The key should be retained as an Acorn-only agenix secret, while the current auth-mini instance is configured once through its authenticated admin API without exposing the key in Git, logs, or Nix store paths.

## Scope

- Encrypt the supplied raw Resend API key for Acorn using agenix.
- Declare the secret with auth-mini-only ownership and restrictive permissions.
- Configure the current auth-mini SMTP state through its authenticated admin API using runtime secret material.
- Use `smtp.resend.com:465`, username `resend`, implicit TLS, and verified sender `auth@0xc1.space`.
- Preserve issuer, RP ID, branding, users, credentials, sessions, and all gateway configuration.
- Deploy/switch Acorn after merge and trigger a real OTP send to the existing admin email.

## Non-Goals

- Do not use the Resend HTTP API for application email delivery.
- Do not commit or log the plaintext API key.
- Do not change the existing admin email, auth methods, gateway policy, or Vaultwarden.
- Do not add general-purpose SMTP module abstractions beyond the Acorn auth-mini need.

## Acceptance Criteria

- A new `.age` secret decryptable by Acorn contains the exact supplied Resend key and the plaintext root file remains untracked.
- Final Nix configuration does not contain the API key in store paths, generated units, command lines, or task documents.
- Acorn toplevel build and focused generated-unit checks pass.
- Live auth-mini config summary reports Resend host, expected port/security, username, and `auth@0xc1.space` without exposing password.
- `POST /email/start` for the existing admin email returns success after deployment.

## Assumptions

- Root file `resent_key` is intentional operator input containing one raw `re_...` Resend key.
- Resend domain `0xc1.space` remains verified; read-only API verification currently reports status `verified`.
- The existing admin email is the intended OTP recipient.
- Acorn can reach `smtp.resend.com` on port 465.

## Constraints

- Secrets must use agenix and remain outside the Nix store.
- Runtime configuration must not print secret contents.
- SMTP configuration must remain compatible with auth-mini's SQLite schema and service sandbox.
- Existing auth-mini data must not be reset.

## Risks

- Auth-mini SMTP state remains application-owned SQLite data; future secret rotation requires an explicit admin API update.
- A valid API key can still fail delivery if sender-domain state changes or Resend account policy rejects the recipient.
- Live OTP testing creates a real one-time code and sends email.

## Recommended Direction

Use a dedicated Acorn agenix secret containing only the raw Resend API key. Declare it with auth-mini-only ownership, then use an authenticated loopback admin API call during this deployment to replace the current SMTP config with Resend. Keep auth-mini database ownership unchanged and document the explicit rotation procedure rather than adding a reconciliation subsystem for this lightweight task.

## Phases

1. Materialize the low-risk contract.
2. Encrypt the key and add the Acorn secret declaration.
3. Validate Nix outputs and secret hygiene.
4. Deliver through PR, switch Acorn, configure auth-mini through the admin API, and run live OTP smoke.
