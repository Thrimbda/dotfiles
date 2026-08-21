# Change Review

## Decision

PASS.

## Blocking Findings

None.

## Correctness Review

- `hosts/acorn/modules/oneex-portfolio-adapter.nix` changes only the package version suffix, producing a fresh Nix output from the same tracked vendor source. It does not alter the adapter protocol, environment, source binding, or service hardening.
- PR #184 was merged before the successful deployment. The prescribed Axiom build transferred the fresh output and activated a new Acorn generation; the old missing store output is not part of the deployed closure.
- Runtime source verification is stronger than an executable-string assertion: 1Exchange returned HTTP `200` and six positions through the registered Custom Account Source, with no self-Fund row.
- The initial owner event wrote exactly one investor profile and one cash flow. The post-write sample's `502` did not trigger a retry. Readback showed the expected temporary double-count state, then one user-approved corrective NAV sample restored total assets, shares, and unit price to the same verified value.
- Final invariant holds: `total_assets=28977.0677876943`, `total_share=28977.0677876943`, `unit_price=1.0`, and the computed ratio matches within tolerance.

## Scope Review

- In scope: fresh adapter derivation identity, Acorn deployment, source recovery, one owner baseline initialization, and one explicitly approved corrective NAV sample.
- Not changed: auth-mini, 1Exchange source/Fund binding, credentials, source header, visibility, subscription state, historical event edits/deletes, taxation, settlement, or external investor flows.

## Security Review

Security lens applied because the change crosses a device-session and signed-source authentication boundary.

- The corrected path retains the `1ex.ntnl.io` audience; it does not weaken audience validation or add a fallback token type.
- Seed, passwords, short-lived tokens, and opaque source headers remained only in protected Acorn runtime memory or temporary root-owned `/run` files. They are absent from task artifacts and configuration diffs.
- Adapter failures remain fail-closed. The observed `502` was contained until a readback and explicit corrective-sample authorization established a safe recovery path.

## Residual Risk

- Upstream source/auth requests can still return transient `502`. Enabled hourly sampling now has a healthy current source, but a future outage should be monitored as an operational event rather than repaired with duplicate cash-flow or investor writes.
