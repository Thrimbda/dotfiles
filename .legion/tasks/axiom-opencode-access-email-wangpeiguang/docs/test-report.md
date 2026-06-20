# Test Report: Axiom Opencode Access Email Allowlist

## Summary

PASS. The repository truth sources and live Cloudflare Access policy now include `wangpeiguangwpg@gmail.com` in the `opencode-axiom.0xc1.space` exact-email allowlist while preserving existing entries. API readback confirms the app is still Google-only, exactly one allow policy contains the four requested emails, and no unsafe broad/bypass allow policy exists.

## Commands And Evidence

### Repo allowlist includes the new email

Command:

```sh
rg -n 'opencode-axiom\.0xc1\.space.*wangpeiguangwpg@gmail\.com' \
  docs/cloudflare-zero-trust.md \
  .legion/wiki/decisions.md \
  .legion/wiki/tasks/axiom-charlie-opencode-access-google-oidc.md \
  .legion/wiki/maintenance.md
```

Result: PASS.

Evidence: each repo/wiki source records `opencode-axiom.0xc1.space` with `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`, and `wangpeiguangwpg@gmail.com`.

### Charlie allowlist remains unchanged

Commands:

```sh
rg -n '`opencode-charlie\.0xc1\.space`: `c1@ntnl\.io`, `siyuan\.arc@gmail\.com`' docs/cloudflare-zero-trust.md
rg -n '`opencode-charlie\.0xc1\.space` allows exact emails `c1@ntnl\.io` and `siyuan\.arc@gmail\.com`' .legion/wiki/decisions.md
rg -n '`opencode-charlie\.0xc1\.space` currently allows `c1@ntnl\.io` and `siyuan\.arc@gmail\.com`' .legion/wiki/tasks/axiom-charlie-opencode-access-google-oidc.md
rg -n '`opencode-charlie\.0xc1\.space` allows `c1@ntnl\.io` and `siyuan\.arc@gmail\.com`' .legion/wiki/maintenance.md
```

Result: PASS.

Evidence: each charlie-specific clause still lists only `c1@ntnl.io` and `siyuan.arc@gmail.com`.

### Credential source and API preflight

Commands:

```sh
agenix -d cloudflare-api-token.age -i "$HOME/.ssh/id_ed25519"
GET /accounts/<account-id>/access/identity_providers
GET /accounts/<account-id>/access/apps?domain=opencode-axiom.0xc1.space&exact=true
GET /accounts/<account-id>/access/apps/<app-id>/policies
```

Result: PASS.

Evidence:

- `hosts/charlie/secrets/cloudflare-api-token.age` decrypts with `~/.ssh/id_ed25519` to env key `API_TOKEN`; token value was not printed.
- Exactly one Cloudflare account was visible to the token.
- Exactly one Google IdP was selected: `399adc69-d770-4685-8acf-cdea3acca230`.
- Exactly one Access app matched `opencode-axiom.0xc1.space`: app `d4fbde13-f314-43e8-9cc8-6243935569c6`, type `self_hosted`, `allowed_idps = [399adc69-d770-4685-8acf-cdea3acca230]`, `auto_redirect_to_identity = true`, `session_duration = 24h`.
- Existing allow policy was `5593f601-c883-4bb8-8e76-1ba02b6c7b4a` with `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`, requiring the Google login method.

### Cloudflare Access policy update and readback

Command:

```sh
PUT /accounts/<account-id>/access/apps/d4fbde13-f314-43e8-9cc8-6243935569c6/policies/5593f601-c883-4bb8-8e76-1ba02b6c7b4a
GET /accounts/<account-id>/access/apps?domain=opencode-axiom.0xc1.space&exact=true
GET /accounts/<account-id>/access/apps/d4fbde13-f314-43e8-9cc8-6243935569c6/policies
```

Result: PASS.

Evidence:

```text
update_success=true
updated_policy={"id":"5593f601-c883-4bb8-8e76-1ba02b6c7b4a","name":"allow-c1-siyuan-froggy-wang-google","decision":"allow","precedence":1,"include":[{"email":{"email":"c1@ntnl.io"}},{"email":{"email":"siyuan.arc@gmail.com"}},{"email":{"email":"froggy2818@gmail.com"}},{"email":{"email":"wangpeiguangwpg@gmail.com"}}],"require":[{"login_method":{"id":"399adc69-d770-4685-8acf-cdea3acca230"}}],"exclude":[]}
final_assertions={"appCount":1,"appShapeOk":true,"exactAllowPolicyCount":1,"unsafeAllowOrBypassCount":0}
```

### Status page scope boundary

Command:

```sh
rg -n 'Do not assume future `opencode-axiom\.0xc1\.space` allowlist changes automatically apply|Future `opencode-axiom` allowlist changes should not automatically expand `status-axiom`' docs/gatus-status.md .legion/wiki/tasks/gatus-axiom-cloudflare-access.md
```

Result: PASS.

Evidence: docs/wiki now explicitly state that `status-axiom` does not automatically inherit future `opencode-axiom` allowlist changes without a separate scoped Access-policy task. This task did not modify `status-axiom` live policy.

### Git hygiene

Command:

```sh
git diff --check
```

Result: PASS. No whitespace errors.

## Why These Checks

- Text assertions prove repo truth sources were updated and that charlie was not expanded.
- Cloudflare API readback is the strongest available evidence for the live Access control-plane state.
- The status-page boundary check prevents a stale doc implication that unrelated `status-axiom` policy automatically follows opencode changes.
- `git diff --check` is sufficient hygiene for this markdown/wiki-only repo diff.

## Manual Smoke Checks

- Browser login as `wangpeiguangwpg@gmail.com` should now pass Cloudflare Access for `https://opencode-axiom.0xc1.space`.
- Browser login with an unlisted Google account should still be denied.
- Existing allowed accounts should continue to pass.
