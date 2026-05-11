# Test Report: axiom/charlie opencode Cloudflare Access Google OIDC

## Summary

PASS with one manual runtime check remaining. Cloudflare API verification proves that both opencode hostnames have exactly one self-hosted Access application, both apps are restricted to the Google identity provider, and both allow policies include only `c1@ntnl.io` plus `siyuan.arc@gmail.com` while requiring the Google login method. The Cloudflare API credential was encrypted to age and plaintext staging was removed.

Manual browser verification with real Google logins remains recommended because this environment cannot prove the interactive Access login/deny UX without using user sessions.

## Pre-Change Discovery

- Command: list Access identity providers with `GET /accounts/<account-id>/access/identity_providers` and sanitize to ID/name/type.
  - Result: PASS.
  - Evidence: exactly one Google candidate was selected: `399adc69-d770-4685-8acf-cdea3acca230` (`Google`, type `google`).

- Command: list Access apps with `GET /accounts/<account-id>/access/apps?domain=<hostname>&exact=true`.
  - Result: PASS.
  - Evidence: `opencode-axiom.0xc1.space` initially had no matching Access app; `opencode-charlie.0xc1.space` had one self-hosted app, `a3885a1c-03b4-48b2-abac-a2c8ebdcfeea`, already restricted to the Google IdP.

- Command: list charlie app policies with `GET /accounts/<account-id>/access/apps/a3885a1c-03b4-48b2-abac-a2c8ebdcfeea/policies`.
  - Result: PASS.
  - Evidence: charlie had policy `613fb592-a015-4208-839f-9238d5a92a85` allowing `c1@ntnl.io` and `siyuan.arc@gmail.com`, but `require` was empty before this task.

## Implementation Evidence

- Command: encrypt the ignored Cloudflare staging env file to age.
  - Result: PASS.
  - Evidence: `config/secrets/cloudflare-access.env.age` exists and was encrypted to the existing `hlissner@global` public age recipient.
  - Safety note: the plaintext staging file was not committed and was removed after API verification.

- Command: create axiom Access application with `POST /accounts/<account-id>/access/apps`.
  - Result: PASS.
  - Evidence: created app `d4fbde13-f314-43e8-9cc8-6243935569c6` named `opencode-axiom`, domain `opencode-axiom.0xc1.space`, type `self_hosted`, `allowed_idps = [399adc69-d770-4685-8acf-cdea3acca230]`, `auto_redirect_to_identity = true`, `session_duration = 24h`.

- Command: create axiom allow policy with `POST /accounts/<account-id>/access/apps/d4fbde13-f314-43e8-9cc8-6243935569c6/policies`.
  - Result: PASS.
  - Evidence: created policy `5593f601-c883-4bb8-8e76-1ba02b6c7b4a`, name `allow-c1-and-siyuan-google`, decision `allow`, precedence `1`, include exact emails `c1@ntnl.io` and `siyuan.arc@gmail.com`, require Google login method `399adc69-d770-4685-8acf-cdea3acca230`.

- Command: update charlie allow policy with `PUT /accounts/<account-id>/access/apps/a3885a1c-03b4-48b2-abac-a2c8ebdcfeea/policies/613fb592-a015-4208-839f-9238d5a92a85`.
  - Result: PASS.
  - Evidence: renamed policy to `allow-c1-and-siyuan-google`, preserved exact emails `c1@ntnl.io` and `siyuan.arc@gmail.com`, and added required Google login method `399adc69-d770-4685-8acf-cdea3acca230`.

## Final Verification

- Command:

```bash
bash -lc 'set -euo pipefail; source <cloudflare-staging>; for each opencode hostname, assert via Cloudflare API that app_count == 1, type == self_hosted, allowed_idps == [google_idp], auto_redirect_to_identity == true, one allow policy has exactly the two emails, requires google login_method, and no bypass/non_identity/broad allow policy exists'
```

  - Result: PASS.
  - Evidence:
    - `opencode-axiom.0xc1.space access assertions passed`
    - `opencode-charlie.0xc1.space access assertions passed`

- Command: check age credential handling.

```bash
test -s config/secrets/cloudflare-access.env.age
test ! -f /home/c1/dotfiles/cloudflare
test ! -f cloudflare
! grep -q 'cloudflare-access\.env\.age' config/secrets/secrets.nix
```

  - Result: PASS.
  - Evidence: age file present; plaintext absent from the main workspace and PR worktree; the age file is not registered in the global agenix map.

- Command: `git diff --check`.
  - Result: PASS.
  - Evidence: no whitespace errors in the repository diff.

## Skipped / Manual Validation

- Interactive browser verification was not run here.
- Recommended manual checks:
  - Authenticate to `https://opencode-axiom.0xc1.space` as `c1@ntnl.io` and confirm Access allows login.
  - Authenticate to `https://opencode-axiom.0xc1.space` as `siyuan.arc@gmail.com` and confirm Access allows login.
  - Repeat the same two allowed-account checks for `https://opencode-charlie.0xc1.space`.
  - Try an unlisted Google account against both hostnames and confirm Access denies it.

## Why These Checks

The API assertions directly prove the Access control-plane state that protects the public hostnames. A Nix build would not prove Cloudflare Access policy behavior, and a browser-only smoke test would not show app/policy rule shape or accidental broad allow/bypass rules. `git diff --check` covers the repository documentation/evidence edits added by this task.
