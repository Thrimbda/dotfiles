# RFC Review: PASS

## Initial Blocking Finding

`docs/rfc.md` permits reuse of an existing matching source based on its public URL, enabled state, and `has_auth_header=true`. 1Ex deliberately omits the stored header from `GET /api/custom-account-sources`, so this cannot prove that a pre-existing source still carries the expected adapter Bearer. A stale or unrelated header would make retries unverifiable and could bind a Fund to a source that cannot read the intended portfolio.

## Required Minimal Fix

Permit reuse only when unified `GET /api/accounts` successfully discovers `ONEEX_PORTFOLIO/<USER_ID>` through that enabled source. If discovery cannot prove the header works, stop without a `PUT` or Fund mutation.

## Resolution

PASS. The RFC now requires successful unified discovery before any existing source can be reused and explicitly rejects `has_auth_header=true` as sufficient evidence. This restores a verifiable retry path without widening the source-update scope.

## Snapshot Clarification

PASS. Live direct and unified reads returned identical product and position ID sets but were timestamped 6.7 seconds apart. The RFC now treats stable identity equality as the source-mapping proof and reserves valuation completeness for the immediate Fund sample, avoiding an unverifiable byte-for-byte requirement across independent live reads.

## Other Review Lenses

- The exclusion-ID reuse avoids an unnecessary secret deployment and has an explicit collision check.
- The source/Fund mutation order, private Fund boundary, immediate sampling, and runtime-secret cleanup are otherwise implementable and rollbackable.
