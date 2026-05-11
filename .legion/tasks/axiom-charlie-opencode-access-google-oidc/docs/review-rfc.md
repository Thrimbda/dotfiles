# Review RFC: axiom/charlie opencode Cloudflare Access Google OIDC

## Verdict

PASS — implementation can begin.

## Blocking Findings

None.

## Review Evidence

- The rebased contract requires reuse of the canonical age-encrypted Cloudflare API token secret at `hosts/charlie/secrets/cloudflare-api-token.age` and forbids a duplicate token secret (`plan.md:15`, `plan.md:26`, `plan.md:37`, `plan.md:43`, `plan.md:70`). The RFC now matches that design by rejecting a second `config/secrets` token and selecting the canonical host-local token secret (`docs/rfc.md:52-58`, `docs/rfc.md:88-93`).
- Repository shape supports the RFC assumption: `hosts/charlie/secrets/cloudflare-api-token.age` exists, `hosts/charlie/secrets/secrets.nix` registers `cloudflare-api-token.age`, and no `config/secrets/cloudflare-access.env.age` file is present in this worktree.
- Implementability remains sufficient: the RFC defines credential-safe discovery and normalization, Google IdP selection, exact app lookup/create/update handling, and exact allow-policy reconciliation for both hostnames (`docs/rfc.md:82-121`).
- Verifiability remains sufficient: the RFC requires API/CLI evidence for the selected Google-compatible provider, one self-hosted app per hostname, restricted `allowed_idps`, exact email include rules, required `login_method`, no broad allow/bypass policy, canonical secret presence, no duplicate age file, and absence of plaintext staging (`docs/rfc.md:130-149`).
- Rollback remains sufficient: the RFC requires sanitized pre-change app/policy state, gives app/policy rollback paths, documents console fallback when credentials are unavailable, and correctly treats canonical-token rollback as token rotation rather than creating another secret (`docs/rfc.md:151-166`).
- Scope remains bounded: the RFC keeps tunnel IDs, DNS routes, cloudflared ingress, opencode service units, Terraform, plaintext token storage, Google OAuth client secrets, and broad identity grants out of scope (`docs/rfc.md:71-78`).
