# RFC Review: Auth Mini Gateway on Acorn

## Decision

PASS

## Blocking Findings

None remaining.

## Reviewed Risk Areas

- Source compatibility: checked upstream gateway code for `GATEWAY_PUBLIC_BASE_URL` and cookie behavior. Initial single-central-gateway design would have failed because `return_to` is same-origin-only and cookies are host-only. RFC was updated to per-origin gateway instances before this PASS.
- Scope control: Vaultwarden remains out of scope, which avoids breaking native client/API behavior.
- Secrets: gateway cookie secret and allowlist are kept in agenix; no plaintext values are required in Nix store paths.
- Rollback: previous htpasswd secret remains declared, and protected vhosts can be restored to Basic Auth without deleting auth databases.
- Verification: RFC includes package builds, host build/eval, nginx shape checks, firewall exposure checks, secret declaration checks, and explicit post-deploy checks.

## Non-Blocking Notes

- `auth-mini` release tag `latest` is mutable upstream. Fixed-output hashing prevents silent mutation, but future upstream refreshes will require an intentional hash update.
- Per-origin gateway instances mean users may receive one gateway session cookie per protected hostname. Auth-mini itself can still provide the shared authentication session on `auth.0xc1.wang`.
