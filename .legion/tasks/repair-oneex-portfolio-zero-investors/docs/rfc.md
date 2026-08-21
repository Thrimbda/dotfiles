# RFC: Repair My Portfolio As A Zero-Investor NAV Viewer

> **Profile**: RFC Heavy (production accounting-history repair)
> **Status**: Approved
> **Owners**: user and agent
> **Created**: 2026-08-21
> **Last Updated**: 2026-08-21

## Executive Summary

- **Problem**: A prior owner initial cash flow remains in Fund event history as
  a portfolio-sized total deposit and issued shares beside the same portfolio's
  Trading NAV, making the Fund page present a duplicate asset-like value.
- **Decision**: Delete only the live-verified initial cash-flow event and its
  owner-profile event, in that order, then preserve the existing Fund with
  self-service subscriptions closed and record a fresh Trading NAV.
- **Why now**: The Fund is a personal NAV viewer; the user confirms neither an
  external nor owner investment exists or should exist.
- **Impact**: The fictitious deposit, active investor, and issued shares return
  to zero while current source-backed total assets and hourly NAV sampling
  continue.
- **Risks**: Event deletion is destructive and event indexes are live. Any
  mismatch, reducer rejection, source failure, or unexpected investor stops the
  repair.
- **Rollback**: No automatic rollback exists after an event deletion. Preserve
  a redacted audit snapshot and require a new explicit accounting decision for
  any later history repair.

## Background And Goals

1Exchange computes Trading Fund NAV as current Trading Account value plus the
Funding Account balance. The prior recovery created one positive owner cash
flow to issue shares even though no investment occurred. A positive funding
balance would become an additional asset component rather than a real
investment; the live preflight further shows that this Fund now retains the
same mistake as total deposit and issued shares even after its funding balance
reached zero.

The goal is a private, enabled portfolio viewer with no current investors or
shares. It should continue recording Trading NAV and should not accept
self-service subscriptions.

## Live Preflight Update

Read-only owner preflight confirmed the exact two-event repair set: an
owner-related profile at event index 26 and a positive owner cash flow at index
27. The other 27 events are Trading NAV samples; no other investor, cash-flow,
settlement, or transfer event exists. The source returned six positions.

The current reducer has zero Funding Account balance and its total assets equal
latest Trading NAV, so the backend is not presently summing the portfolio twice.
It still projects the fictitious initialization as a portfolio-sized total
deposit, issued shares, and one active investor. The Fund detail view renders
NAV and Total deposit separately, which makes the unwanted investor state look
like a second asset value. The same bounded deletion remains the correct repair
because it removes that false investment while preserving Trading NAV history.

## Non-goals

- Change the adapter, source binding, Fund ID, owner/admin authorization,
  credentials, access grants, visibility, target currency, or hourly sampling.
- Create a compensating negative cash flow, investor exit, settlement, transfer,
  replacement Fund, or historical Trading NAV rewrite.
- Make privileged owner/admin accounting endpoints unavailable. Closing
  `subscription_open` only disables self-service investment paths.

## Constraints

- Read the live Fund state before every mutation and use only returned event
  indexes. Never infer or reuse a historical index.
- Proceed only when the event stream proves exactly the approved owner profile
  and positive initial cash-flow artifacts, with no unrelated investor or cash
  flow to preserve.
- Delete the positive cash flow first, then re-read all relevant projections
  before deleting the owner profile. Stop after any request failure rather than
  retrying blindly.
- Preserve all existing Fund configuration fields during the upsert and set only
  `subscription_open=false` as a deliberate configuration assertion.
- Keep all runtime auth material and opaque source details out of evidence.

## Proposed Design

### Read-only Preflight

Use an authenticated owner session to read Fund configuration, Fund statement,
active investors, NAV history, source positions/health, and a full relevant
event page. Capture only redacted structural evidence: Fund enablement and
subscription flags, counts, equity/funding/share totals, event indexes, event
types, timestamps, and whether each candidate belongs to the approved owner
initialization.

The operation stops without mutation unless all conditions hold:

1. The source is readable and a current sample can be taken safely.
2. The Fund is the expected private Fund and has the expected trading account.
3. There is exactly one active owner investor caused by one profile event and
   exactly one positive initial cash-flow event associated with it.
4. No other investor, cash-flow, settlement, transfer, or unexpected account
   event makes the delete set ambiguous.

### Bounded Accounting Repair

1. Delete the verified positive cash-flow event by its current event index.
2. Re-read statement, investors, NAV, and events. Stop if the event is still
   present, the reduced stream is invalid, a Funding Account balance remains
   unexpectedly, or unrelated state changed.
3. Delete the verified owner-profile event by its current event index.
4. Re-read the same state again. Stop if any active investor or issued shares
   remain.
5. Upsert the existing Fund using current configuration fields, preserving its
   trading account, type, visibility, enablement, target currency, and
   description while setting `subscription_open=false`.
6. Take exactly one fresh owner-authorized sample. This is a Trading NAV event,
   not an investor, cash-flow, share, or settlement event.

### Verification Invariant

The immediate sample equity must equal the Fund's current total assets once the
Funding Account balance is zero. Verification also requires zero active
investors, zero issued shares, private visibility, enabled sampling, closed
subscriptions, no new funding/cash-flow event, and no source or credential
change. A zero-share Fund reports unit price `1` by design; total-assets NAV is
the viewer metric.

## Alternatives Considered

### Option A: Delete the exact initial cash flow and owner profile

- Pros: removes the false investor/deposit component, leaves only source-backed
  NAV, meets the requested zero-investor state, and preserves Fund identity/history.
- Cons: destructive accounting-history repair with no automatic rollback.

### Option B: Add a negative cash flow or redeem the owner

- Pros: can offset current total assets without deleting history.
- Cons: records an investment/redemption that never occurred, can leave an
  investor history or shares, and violates the user's no-investment intent.

### Option C: Keep the owner shares and only close subscriptions

- Pros: no destructive history mutation.
- Cons: does not remove the fictitious deposit/shares or meet zero-investor
  acceptance.

### Decision

Choose Option A. It is the smallest correction that restores the intended
accounting model without inventing a new flow or replacing the Fund.

## Rollout And Rollback

### Rollout

1. Complete the read-only live gate and save redacted evidence.
2. Delete cash flow, verify; delete profile, verify.
3. Reassert closed subscriptions through a preserving upsert.
4. Take one sample and prove all final invariants.

### Stop Conditions

- Any unexpected event, investor, cash flow, Fund configuration, source error,
  reducer failure, or event-index mismatch stops the operation.
- A timeout or ambiguous delete response triggers a fresh read-only check; no
  repeat DELETE is sent unless the read proves the first request had no effect
  and the user explicitly reconfirms the retry boundary.

### Rollback

Before the first DELETE, stop safely with no production change. After a
successful deletion, do not recreate an owner investment or edit history
automatically. If recovery is necessary, retain the redacted event audit and
open a separate explicit accounting-repair decision.

## Observability And Security

- Record event count/type/index transitions, investor/share/funding totals,
  sample equity, total assets, source status, subscription flag, and API status
  classes without tokens, IDs that reveal credentials, headers, or payload
  secrets.
- Confirm the `DELETE` response and post-delete read separately. A successful
  transport response is not sufficient evidence of correct reduced state.
- The Fund remains private. `subscription_open=false` is the self-service
  boundary; no public subscription request should succeed.

## Testing Strategy

- Static: review the documented 1Exchange Fund event and sample semantics.
- Live read-only: verify the exact candidate events, current Fund configuration,
  source health, and pre-repair fictitious-deposit relation.
- Mutation: prove reducer validity after each deletion and one preserving Fund
  upsert.
- Final: compare immediate sample equity to total assets, assert zero investors
  and shares, zero funding component, private/closed configuration, and absence
  of any new cash-flow event.

## Milestones

1. Design and review
   - Scope: research, RFC, and adversarial review of event selection/order.
   - Acceptance: no unresolved accounting or authorization ambiguity.
   - Rollback impact: none.
2. Live preflight
   - Scope: redacted, read-only state capture.
   - Acceptance: exact event candidates and repair invariants are proven.
   - Rollback impact: none.
3. Bounded repair and verification
   - Scope: two approved deletes, preserving Fund upsert, one NAV sample, and
     post-repair verification.
   - Acceptance: zero-investor NAV-only Fund state.
   - Rollback impact: manual follow-up only after a successful delete.

## Open Questions

- None blocking design. The live gate decides whether the approved delete set
  exists; a mismatch is a stop reason, not an invitation to broaden scope.

## References

- Contract: `../plan.md`
- Research: `research.md`
- Previous recovery: `.legion/tasks/restore-oneex-portfolio-audience-nav/docs/test-report.md`
- Fund API reference: `/home/c1/Work/1ex-portfolio/.agents/skills/use-1exchange/references/fund-apis.md`
