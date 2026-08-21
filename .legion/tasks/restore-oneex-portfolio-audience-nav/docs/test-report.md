# Verification Report

## Result

PASS. The merged fresh adapter output is active on Acorn, the 1Exchange Custom Account Source reads six fully usable positions, and `My Portfolio` now has one owner position with a correct unit NAV calculation.

## Deployment

The first attempts exposed two Axiom-only blockers: unrelated desktop-module assertions, then a locally registered but missing old adapter store output. The latter could not be repaired or safely deregistered by the local daemon, so PR #184 changed only the adapter package version suffix to force a fresh output from the unchanged vendor source.

The prescribed Axiom-to-Acorn command completed successfully after #184 merged:

```sh
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

It built and transferred the fresh adapter output, activated Acorn generation `7yhal1xrcwf8yvlph9rrcdzk5dnyyj0d`, and restarted `oneex-portfolio-adapter.service`. Acorn never built the closure locally.

The fresh adapter release build passed all 10 unit tests. Runtime verification confirmed the service is active and uses the fresh `audience-rebuild1` output.

## Source And Fund Preflight

An Acorn-root short-lived session was minted with `redirect_uri=https://1ex.ntnl.io`; the session authenticated to 1Exchange without exposing its token or seed.

```text
service_active=true
adapter_output_is_fresh=true
source_positions_status=200
source_position_count=6
recursive_fund_rows=0
fund_enabled=true
fund_total_assets=29017.357998073378
fund_unit_price=1.0
total_share=0
investor_count=0
```

This proves the deployed adapter can now authenticate upstream, 1Exchange can value its source, and the self-Fund exclusion remains effective.

## Owner Unit Initialization And Corrective Sample

The guarded initialization obtained a positive, fully priced pre-write sample and then atomically created exactly two events: the owner profile and one positive initial cash flow. The immediately following sample returned `502`; the command stopped without retrying, deleting, or creating any additional investor/cash-flow event.

Readback confirmed the expected temporary reducer state: one investor, `28977.0677876943` shares, total assets double the prior trading NAV, and unit price `2.0`. A later read-only source check returned `200` with six positions. The user explicitly approved one corrective NAV sample; it appended only a current trading NAV event and did not create another investor, cash flow, or share issuance.

```text
corrective_sample.equity=28977.0677876943
corrective_sample.positions=6
corrective_sample.unpriced=0
total_assets=28977.0677876943
total_share=28977.0677876943
unit_price=1.0
unit_price_matches_assets_over_shares=true
```

## Security And Scope

- No password, seed, bearer, decrypted environment value, or stored source header was printed or committed.
- No auth-mini, 1Exchange, source/Fund binding, credential, or historical event was modified outside the approved owner initialization and its explicitly approved corrective NAV sample.
- Future enabled hourly samples now update total assets; with nonzero fixed shares, the Fund unit price moves with the portfolio rather than using the zero-share fallback of `1`.
