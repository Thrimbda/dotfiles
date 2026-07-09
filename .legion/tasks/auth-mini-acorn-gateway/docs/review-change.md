# Change Review: Auth Mini Gateway on Acorn

## Decision

PASS

## Blocking Findings

None.

## Security Lens

Applied. This change modifies authentication, session boundaries, secrets, nginx trust boundaries, and public ingress behavior.

## Scope Review

- In scope: added `auth-mini` and `auth-mini-gateway` packages, Acorn services, encrypted gateway env secret, new auth/gateway vhosts, and gateway protection for status/opencode/frps dashboard.
- In scope: left existing frp topology and firewall exposure unchanged.
- In scope: kept Vaultwarden unchanged to avoid breaking native clients.
- No out-of-scope implementation changes found.

## Correctness Review

- Package sources are pinned by fixed hashes. `auth-mini-gateway` builds from a pinned commit and its Rust tests pass during packaging.
- The initial central-gateway design risk was resolved before implementation: each protected hostname now has an origin-scoped gateway instance, matching upstream same-origin return validation and host-only cookie behavior.
- Generated nginx config renders full public hostnames, not internal instance names.
- Protected vhosts no longer use `basicAuthFile`; they render `auth_request /_auth`, internal auth check locations, login redirect locations, and per-origin gateway ports.
- `auth-mini` and gateway backend ports are loopback-only by service config and are not added to the firewall.
- Gateway secret is age-encrypted and owned by `auth-mini-gateway` with mode `0400`.

## Residual Risks

- Live deployment still needs DNS records, ACME issuance, auth-mini admin bootstrap, issuer/RP configuration, and browser smoke checks.
- The `auth-mini` release URL uses upstream tag `latest`. Fixed-output hashing prevents silent mutation, but a future upstream refresh will require an intentional hash update.
- Gateway session cookies are per protected hostname because upstream does not set a shared cookie domain. This is expected for the current design but means each hostname may need its own gateway session.

## Evidence Reviewed

- `docs/rfc.md`
- `docs/review-rfc.md`
- `docs/test-report.md`
- staged implementation diff for `hosts/acorn`, `packages/auth-mini`, and `packages/auth-mini-gateway`
- generated nginx config evidence recorded in the test report
