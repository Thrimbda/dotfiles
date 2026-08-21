# RFC Review

## Decision

PASS.

## Blocking Findings

None.

## Review Evidence

- The RFC treats the user-confirmed removal of the owner profile and initial
  cash flow as a destructive accounting-history repair rather than attempting
  a fictional negative flow or redemption.
- It requires a live read-only event gate before mutation, so historical task
  notes cannot select a stale event index or broaden the delete set.
- Deletion order is correct for the documented model: remove the positive cash
  flow before the investor profile, then re-read all event and statement state
  before selecting the second live index.
- The proposed Fund upsert preserves current values while asserting
  `subscription_open=false`; it explicitly distinguishes that self-service
  boundary from privileged Owner/admin accounting authority.
- Final verification is measurable: source health, fresh sample equity, total
  assets, zero Funding Account contribution, zero active investors, zero shares,
  private/closed configuration, and no new cash-flow event.
- The RFC makes the non-automatic rollback boundary explicit. A successful
  deletion cannot safely be undone by silently creating a new investment event.

## Non-blocking Notes

- The live preflight must record event types and structural relationship only;
  do not copy opaque payload values, bearer values, or source headers into task
  evidence.
- If an HTTP timeout occurs after a DELETE, a fresh read determines whether it
  took effect. The operation must not repeat the DELETE based only on transport
  uncertainty.

## Implementation Gate

The design is approved for redacted live preflight. Any live mismatch returns
the task to a blocked decision state and does not authorize adjacent event
repair.

## Retry Amendment Review

PASS. The user-authorized retry change is limited to idempotent source-position
reads and has a bounded execution window. It does not weaken the exact
event-selection rule or permit repeated DELETE, Fund-upsert, or sample writes.
A healthy response still requires fresh event-index selection before mutation,
so transient source recovery cannot turn stale evidence into a destructive
operation.
