# Auth Mini Resend SMTP

## Metadata

- `task-id`: `auth-mini-resend-smtp`
- `status`: `ready for PR; live SMTP configured`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`

## Outcome Summary

Acorn auth-mini now uses Resend SMTP for email OTP delivery: `smtp.resend.com:465`, username `resend`, implicit TLS, and sender `auth-mini <auth@0xc1.space>`. The Resend API key is retained as the Acorn-only encrypted secret `hosts/acorn/secrets/auth-mini-resend-api-key.age` and deploys to `/run/agenix/auth-mini-resend-api-key` as `auth-mini:auth-mini` mode `0400`.

The application SMTP state was configured once through auth-mini's authenticated loopback admin API. A live OTP request returned `200`, and Resend send history recorded the message to the existing admin email.

## Reusable Decisions

- Keep provider API keys in host-recipient agenix files even when the application persists its own configuration in SQLite.
- For lightweight application-owned config, do not add a startup reconciliation subsystem unless rotation/recovery automation is an explicit requirement.
- Resend SMTP uses verified sender `auth@0xc1.space`; use port `465` with implicit TLS and username `resend`.
- Future key rotation or database recovery requires an authenticated admin API update after changing the age secret.

## Validation

- Resend domain `0xc1.space` is verified.
- Encrypted secret decrypt-roundtrip matched the operator input without plaintext output.
- Acorn toplevel build passed.
- Evaluated runtime ownership is `auth-mini:auth-mini`, mode `0400`.
- Live SMTP config read-back matched Resend settings.
- Live `/email/start` returned `200 {"ok":true}` and provider history recorded the OTP message.
- Security/readiness review passed with no blockers.

## Operational Follow-Up

- After merge and Acorn switch, verify `/run/agenix/auth-mini-resend-api-key` ownership and mode.
- Remove the plaintext root operator-input file after confirming no further local use is needed.

## Related Raw Sources

- `plan`: `.legion/tasks/auth-mini-resend-smtp/plan.md`
- `log`: `.legion/tasks/auth-mini-resend-smtp/log.md`
- `tasks`: `.legion/tasks/auth-mini-resend-smtp/tasks.md`
- `test-report`: `.legion/tasks/auth-mini-resend-smtp/docs/test-report.md`
- `change-review`: `.legion/tasks/auth-mini-resend-smtp/docs/review-change.md`
- `walkthrough`: `.legion/tasks/auth-mini-resend-smtp/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/auth-mini-resend-smtp/docs/pr-body.md`
