## Summary

- retain the Resend SMTP credential as an Acorn-only agenix secret
- deploy it for `auth-mini:auth-mini` with mode `0400`
- add the corresponding Acorn recipient declaration

The application SMTP configuration and a live OTP send already succeeded. This PR adds the Acorn agenix retention/deployment declaration; it does not add SMTP reconciliation logic.

## Validation

- `nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel`
- `git diff --check`
- encrypted-secret roundtrip and plaintext-leak checks
- live Resend SMTP read-back and connectivity check
- live `/email/start`: `200 {"ok":true}`, with provider send history confirmation
- security/readiness review: PASS, no blocking findings

## After merge

Switch Acorn and verify `/run/agenix/auth-mini-resend-api-key` is owned by `auth-mini:auth-mini` with mode `0400`. A second OTP send is unnecessary unless the live SMTP configuration changes.
