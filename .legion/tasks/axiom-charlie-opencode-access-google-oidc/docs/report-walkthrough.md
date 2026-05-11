# Report Walkthrough: axiom/charlie opencode Cloudflare Access Google OIDC

## Mode

Implementation mode. This walkthrough summarizes already-recorded delivery evidence from the task contract, RFC, test report, and change review; it does not add new verification.

## What Changed

- Cloudflare Access is now the intended authentication boundary for both opencode tunnel hostnames, matching the contract goal in `plan.md` and the RFC decision in `docs/rfc.md`.
- Live Cloudflare Access state was reconciled for:
  - `opencode-axiom.0xc1.space`
  - `opencode-charlie.0xc1.space`
- The verified Access shape is Google-only login with exact-email allow entries for:
  - `c1@ntnl.io`
  - `siyuan.arc@gmail.com`
- Repository docs/wiki evidence was updated so future operators do not treat cloudflared ingress alone as sufficient authentication.
- The Cloudflare API credential used for the operation was stored as `config/secrets/cloudflare-access.env.age`.

## Evidence Summary

- `docs/test-report.md` records Cloudflare API discovery and mutation evidence:
  - selected Google identity provider `399adc69-d770-4685-8acf-cdea3acca230`;
  - created the axiom self-hosted Access app and exact-email allow policy;
  - updated the existing charlie allow policy to require the Google login method;
  - final API assertions passed for both hostnames.
- `docs/test-report.md` also records repository/secret hygiene:
  - `config/secrets/cloudflare-access.env.age` exists;
  - the plaintext Cloudflare staging file was removed;
  - `cloudflare-access.env.age` is not registered in `config/secrets/secrets.nix`, so it is not part of the global agenix deployment map;
  - `git diff --check` passed.
- `docs/review-change.md` records a PASS verdict with no blocking findings, including security review of Access policy shape, scope compliance, and verification sufficiency.

## Reviewer Notes

- The change intentionally does not modify opencode services, tunnel IDs, DNS routes, cloudflared connector modules, host deployments, or add Terraform/new auth schemes.
- Manual browser smoke checks remain recommended because this environment did not exercise interactive Google login sessions. Recommended checks are listed in `docs/test-report.md`: both allowed accounts should be tested against both hostnames, and one unlisted Google account should be denied.
- The encrypted Cloudflare credential is ops/config material only in this task. It is age-encrypted, but not registered in the global agenix map.

## Remaining Non-Blocking Follow-Up

- Run manual browser smoke checks for both allowed identities and a denied unlisted Google identity after deployment/review.
- Delete the mistakenly created `axiom-opencode.0xc1.space` CNAME as tracked separately in `.legion/wiki/maintenance.md`.
