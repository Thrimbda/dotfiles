# Delivery Walkthrough

> **Mode**: implementation

## Outcome

`My Portfolio` now tracks the deployed portfolio source with issued owner units. At the corrected baseline, total assets and total shares are both `28977.0677876943 USD`, yielding a verified unit price of `1.0`. Future enabled Fund samples will move the unit price with the portfolio instead of using the zero-share fallback.

## What Changed

- PR #184 introduced a fresh Nix adapter output identity, allowing Axiom to build the existing vendor source without requiring its registered-but-missing old output.
- The merged `master` deployment built on Axiom, transferred the new closure, and activated Acorn generation `7yhal1xrcwf8yvlph9rrcdzk5dnyyj0d`.
- The live Custom Account Source now returns HTTP `200`, six positions, and no recursive self-Fund row.
- One owner initialization created exactly one investor profile and one initial cash-flow event from a fully priced pre-write sample.
- The first post-write sample returned `502` and was not retried. Readback proved the temporary double-count state; after explicit user approval, one corrective NAV sample restored the intended accounting projection.

## Evidence

- `docs/test-report.md`: Axiom deployment, fresh output, source health, initialization chronology, corrective sample, and final assets/shares/unit-price invariant.
- `docs/review-change.md`: PASS with correctness, scope, and authentication/security review.
- `docs/rfc.md`: approved deployment, accounting, rollback, and non-retry boundaries.

## Operational Boundary

- No secret, bearer, source header, credential, Fund/source rebinding, historical event edit/delete, taxation, or settlement action was introduced.
- A future source outage remains fail-closed. Treat it as an operational monitoring event; do not create duplicate owner cash flows or shares to repair it.
