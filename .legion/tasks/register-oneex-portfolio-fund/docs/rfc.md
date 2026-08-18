# RFC: Register My Portfolio as a Private 1Ex Fund

## Decision

Create one enabled Custom Account Source named `1Ex Portfolio Adapter` and one private, non-subscribable USD Trading Fund named `My Portfolio`. Reuse the already deployed, preflight-verified-unused `EXCLUDED_FUND_ID` as the Fund ID. This makes the adapter omit the Fund on every future upstream read without changing Acorn configuration.

The source uses `https://1ex-portfolio.0xc1.wang` and the adapter's existing derived `Bearer` header. The header is derived only in Acorn root runtime memory and stored by 1Ex; it is never written into Nix, task documents, command output, or the repository.

## Why This Path

Reusing the deployed exclusion UUID is the minimal correct option. Generating a new Fund ID would require decrypting, re-encrypting, building, and remotely applying an otherwise unnecessary Acorn secret update. The current UUID is random, stable, and confirmed not to collide with any of the eight readable Funds.

The Fund is private and has `subscription_open=false` because it is a personal portfolio projection, not an investable public vehicle. It uses `trading_account_id=ONEEX_PORTFOLIO/<USER_ID>`, `fund_type=trading`, `target_currency=USD`, and `enabled=true` so 1Ex can sample the adapter's live USD positions.

## Mutation Sequence

1. Mint a fresh user session on Acorn from the existing runtime identity; confirm the subject matches `USER_ID`.
2. Re-read owned sources and readable Funds. If a matching source or target Fund already exists but does not match the intended shape, stop rather than overwrite it.
3. Create the source only when absent. Confirm it is enabled, has an auth header, and unified `GET /api/accounts` advertises the adapter AccountID. For a source that already exists on a retry, this discovery check is required before it can be reused.
4. Create the Fund with the deployed exclusion UUID. Confirm its owner-visible privacy, enabled, USD, trading-account, and subscription settings.
5. Immediately sample the Fund. Require finite positive USD equity, no unpriced positions, and a position count consistent with the source response.
6. Read the adapter directly after Fund creation and require that no mapped position has `product_id=FUND/<Fund ID>` or `position_id=ONEEX_PORTFOLIO/<USER_ID>/FUND/<Fund ID>`.
7. Log out the short-lived user session and remove all `/run` operator files.

## Idempotency And Conflict Policy

- Existing source absent: create it. An existing source can be reused only when its public URL and enabled state match, it reports an auth header, and unified discovery actually returns the adapter AccountID. `has_auth_header=true` alone is not evidence that the opaque stored header is correct. Any other matching-name or conflicting source: stop.
- Existing Fund absent: create it. Existing Fund with the target ID and exact intended shape: reuse it. Any conflicting target ID or `My Portfolio` record: stop.
- Do not use `PUT` to repair an existing source or Fund in this task. Explicit follow-up is required for an unexpected pre-existing shape.

## Security Boundaries

- The 1Ex user bearer and adapter Bearer are distinct. The former authorizes 1Ex mutations; the latter is stored only as the source's outbound Authorization header.
- The raw seed never leaves Acorn. The one-time signing material is protected by root-only `/run` files and cleanup traps.
- The adapter remains loopback-only behind nginx and retains its existing bearer check. No management endpoint or long-lived admin credential is added.

## Rollback

- Before Fund creation, delete the newly created source if registration validation fails.
- After Fund creation, disable the new Fund by an explicit owned-Fund update before attempting source removal. If 1Ex refuses source deletion because the Fund still references it, leave the private Fund disabled and record the source/Fund IDs for a dedicated cleanup task.
- The Acorn service, encrypted environment, and all pre-existing Funds remain unchanged, so no NixOS generation rollback is needed.

## Validation

- Direct adapter discovery/positions and unified 1Ex discovery both succeed for the same AccountID and return the same stable product and position IDs. Each request is a fresh live snapshot, so different `updated_at` values or transient valuation changes are not treated as a mapping mismatch.
- Source configuration is enabled and reports `has_auth_header=true` without revealing the header.
- The Fund's immediate sample reports USD, finite positive equity, `unpriced_positions=0`, and expected source-position coverage.
- Direct adapter output excludes the new Fund's ID, proving the recursion guard works.
