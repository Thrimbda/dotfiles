# Research Notes

## Problem Restatement

- `My Portfolio` is intended to be a private, NAV-only projection of the
  portfolio adapter, not an investment vehicle.
- Historical recovery evidence records one owner profile and one positive
  initial cash-flow event. The Fund model adds Funding Account balance to
  Trading NAV, so that cash flow can make the same portfolio value appear twice.

## Relevant Entry Points

- `GET /api/funds`, `GET /api/fund-statements`, `GET /api/fund-nav`, and
  `GET /api/fund-statement-events` establish the live configuration, reduced
  state, NAV, and mutable event indexes.
- `DELETE /api/fund-statement-events?fund_id=...&event_index=...` is the
  destructive accounting repair surface. The server rejects a deletion when
  the remaining event stream is not reducible.
- `POST /api/funds` preserves an owned Fund while explicitly setting
  `subscription_open=false`; it does not prevent an Owner or admin from using
  privileged accounting endpoints manually.
- `POST /api/funds/sample?fund_id=...` appends `trading_nav_set`, whose total
  NAV is Trading NAV plus current Funding Account balance.

## Existing Conventions

- The Fund is private, enabled, backed by the adapter Custom Account Source,
  and excludes its own Fund row from direct source output.
- Source/auth failures fail closed. A failed read or sample is a stop condition,
  not a reason to create a compensating accounting event.
- Secrets, device sessions, bearer values, source headers, and decrypted
  runtime values must not enter evidence artifacts.

## Historical Evidence

- `restore-oneex-portfolio-audience-nav/docs/test-report.md` records the
  initial owner profile plus positive cash flow and a later sample. It observed
  a temporary doubled total before treating a follow-up sample as corrective.
- The Fund API model states that a fresh sample still adds Funding Account
  balance. Therefore a retained positive cash flow remains a causal candidate
  for the reported double count.
- The user explicitly confirmed removal of the owner profile and initial cash
  flow and requested zero investors with subscriptions closed.

## Residual And Live Gate

- Explained: a positive Funding Account balance plus a live Trading NAV can
  explain a doubled total-assets projection.
- Residual: current event indexes, event payload shape, current funding balance,
  subscription state, and any events added after the historical recovery are
  unknown until live read-only preflight.
- Expansion: continue only if the live stream contains exactly the expected
  owner profile and positive initial cash-flow artifacts, the source is healthy,
  and no unrelated investor or cash-flow event exists. Otherwise stop and
  report the mismatch without mutation.

## Live Preflight Evidence

- A fresh owner-authenticated, read-only session confirmed a private, enabled
  Trading Fund with `subscription_open=false` and a healthy six-position source.
- The current reducer reports zero Funding Account balance and a total-assets
  value equal to its latest Trading NAV. It does not currently add the initial
  cash flow into `total_assets` a second time.
- The event stream contains 29 rows: 27 `trading_nav_set` rows, one
  owner-related `investor_profile_updated` at index 26, and one owner-related
  positive `cash_flow_recorded` at index 27. There are no other investor,
  cash-flow, settlement, or transfer artifacts.
- The reducer nevertheless retains the same initial amount as `total_deposit`,
  issued shares, and one active investor. This violates the user's intended
  zero-investor model even when Funding Account balance is zero.
- The public Fund-detail bundle renders latest NAV and settlement-preview Total
  deposit as separate values; it does not add them client-side. Removing the
  fictitious deposit and shares removes the misleading second portfolio-sized
  value without requiring a frontend change.

## Risks And Non-goals

- Delete the cash-flow event before the profile event. After each delete, read
  the statement and event page again because indexes or reducer validity can
  change.
- Do not use a negative cash flow, investor exit, settlement, Fund replacement,
  source rebinding, or historical Trading NAV rewrite as a substitute for this
  correction.
- Zero shares intentionally yield a unit price of `1`; the relevant viewer
  measure is the Fund total-assets NAV series.

## References

- Task contract: `../plan.md`
- Previous recovery evidence:
  `.legion/tasks/restore-oneex-portfolio-audience-nav/docs/test-report.md`
- Current knowledge:
  `.legion/wiki/tasks/restore-oneex-portfolio-audience-nav.md`
- API reference:
  `/home/c1/Work/1ex-portfolio/.agents/skills/use-1exchange/references/fund-apis.md`
