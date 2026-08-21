# Live Preflight Report

## Result

PASS. Read-only owner preflight identified exactly the user-approved
initialization artifacts and no adjacent accounting event that would broaden the
repair scope.

## Fund And Source

```text
fund_enabled=true
fund_private=true
subscription_open=false
fund_type=trading
source_positions=6
```

The current reducer has zero Funding Account balance. Its total assets equal
latest Trading NAV; a normal live-source drift exists between the current
position read and the older last sample, but neither value is doubled.

## Event Gate

```text
event_count=29
trading_nav_set=27
owner_profile_event_index=26
owner_positive_cash_flow_event_index=27
other_investor_cash_flow_settlement_or_transfer_events=0
active_investors=1
```

The positive cash flow is the only retained source of the fictitious total
deposit and issued shares. It is therefore the first bounded delete target. The
profile remains the second target only after a fresh event read proves it is
still the same lone owner profile.

## Viewer Finding

The Fund-detail client renders latest NAV and Total deposit independently; it
does not add them in JavaScript. Current total assets are not backend-doubled,
but the portfolio-sized fictitious deposit/owner position presents a second
asset-like value. Removing the two initialization artifacts satisfies the
requested zero-investor viewer model without a frontend code change.

## Safety Boundary

- No DELETE, Fund update, sample, source change, or accounting write occurred
  during preflight.
- Session token, private-key seed, source header, and Fund ID were not emitted.
- The next operation must mint a new short-lived session, repeat the exact
  event gate, delete cash flow first, and stop on any mismatch.

## Fresh Mutation Gate

The fresh source-positions check immediately before the first planned DELETE
returned `502`. The command validates source health before selecting or deleting
an event, so it stopped before any DELETE, Fund update, or sample request. The
earlier read-only event proof remains valid evidence of the intended repair set,
but it is not permission to mutate while the source is unhealthy.

The user authorized one fresh retry. That retry also returned `502` before any
mutation. The adapter service remained `active`; its recent journal showed two
successful six-position reads followed by the two failed reads. This identifies
an intermittent source-read failure, not a stopped adapter service, but does
not establish whether the failing dependency is auth, upstream data, or another
fail-closed adapter boundary.

## Blocked Handoff

- No accounting repair was applied. The owner profile, positive cash-flow event,
  shares, and total deposit remain unchanged.
- Branch: `legion/repair-oneex-portfolio-zero-investors`.
- Worktree: `.worktrees/repair-oneex-portfolio-zero-investors`.
- Resume condition: obtain new user authorization for another fresh source
  preflight after the adapter returns a healthy position read. Then repeat the
  full event gate before any DELETE; never reuse the historical event indexes.
