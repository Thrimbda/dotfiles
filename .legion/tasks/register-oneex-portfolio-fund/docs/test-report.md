# Verification Report

## Result

PASS. `My Portfolio` is an enabled private USD Fund backed by the deployed Custom Account Source. It has an initial NAV and the adapter excludes the Fund itself while continuing to expose five underlying positions.

## Why These Checks

This task makes no Nix or adapter source change: preflight proved that the deployed exclusion UUID could be reused. The strongest evidence is therefore authenticated 1Ex runtime state plus direct adapter behavior, rather than an unrelated local closure build.

## Authenticated Preflight

A short-lived Ed25519 session minted on Acorn matched the configured user identity. Before mutation:

```text
custom_source_count=0
matching_source_count=0
fund_count=8
matching_fund_count=0
configured_exclusion_matches_existing_fund_count=0
```

The session seed, access token, adapter bearer, and stored source header were never printed. Root-owned `0600` `/run` files were deleted on command exit.

## Source Registration

The source was created with the public HTTPS base URL and runtime-derived adapter bearer. Readback verified:

```text
source_action=created
source_enabled=true
source_has_auth_header=true
unified_account_discovery=present
```

Direct adapter and unified 1Ex reads each returned five positions with identical stable product and position ID sets. Their `updated_at` values differed by 6.7 seconds, and live valuations differed accordingly; this is expected for independent fresh upstream snapshots and not a mapping change.

## Fund Creation And Sampling

The Fund was created with the deployed exclusion UUID, `name=My Portfolio`, `trading_account_id=ONEEX_PORTFOLIO/<USER_ID>`, `target_currency=USD`, `is_public=false`, and `subscription_open=false`.

The first mutation's sample result was not retained and failure cleanup disabled the new Fund. A single non-retried disabled-state sample then passed:

```text
sample_status=200
sample_currency=USD
sample_positions=5
sample_unpriced=0
sample_equity_positive=true
```

Afterward the exact intended Fund configuration was enabled and read back:

```text
source_state.enabled=true
source_state.has_auth_header=true
account_match_count=1
fund_state.name=My Portfolio
fund_state.enabled=true
fund_state.is_public=false
fund_state.subscription_open=false
fund_state.target_currency=USD
latest_nav_count=1
```

## Recursion Guard

With the Fund enabled, a direct adapter read returned five underlying positions and no row for the Fund:

```text
enabled_fund_direct_exclusion=confirmed
direct_position_count=5
```

This proves `EXCLUDED_FUND_ID` matches the created Fund ID and prevents the portfolio Fund from valuing itself recursively.

## Skipped Work

No Acorn secret, systemd, nginx, or adapter source change was necessary, so no Nix build or remote switch was run. Existing Funds, credentials, and account mappings were not modified.
