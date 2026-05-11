## Summary

- Reconciles live Cloudflare Access state for `opencode-axiom.0xc1.space` and `opencode-charlie.0xc1.space` so both use Google-only Access with exact-email allow rules for `c1@ntnl.io` and `siyuan.arc@gmail.com`.
- Adds `config/secrets/cloudflare-access.env.age` as the encrypted ops credential, removes the plaintext staging file, and leaves the token unregistered in the global agenix map.
- Updates task evidence plus directly relevant docs/wiki notes so cloudflared ingress is not treated as sufficient authentication.

## Verification

- PASS: Cloudflare API assertions recorded in `docs/test-report.md` confirm each hostname has exactly one self-hosted Access app, Google-only `allowed_idps`, an allow policy with the two exact emails, required Google `login_method`, and no broad/bypass/non-identity allow policy.
- PASS: Secret hygiene checks recorded in `docs/test-report.md` confirm the age file exists, plaintext staging is absent, and `config/secrets/secrets.nix` does not register the token for global agenix deployment.
- PASS: `git diff --check` recorded in `docs/test-report.md`.
- PASS: `docs/review-change.md` reports no blocking correctness, scope, verification, or security findings.

## Manual Follow-Up

- Manual browser smoke checks remain recommended: test both allowed Google accounts against both hostnames and confirm an unlisted Google account is denied.
