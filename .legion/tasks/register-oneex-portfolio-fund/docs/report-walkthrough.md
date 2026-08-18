# Portfolio Fund Walkthrough

## Mode

`implementation`

## Delivered State

- Registered `1Ex Portfolio Adapter` as an enabled Custom Account Source at `https://1ex-portfolio.0xc1.wang` with its runtime-derived bearer header.
- Created `My Portfolio` as the user's enabled private USD Trading Fund, bound to the adapter AccountID with subscriptions closed.
- Reused the deployed exclusion UUID as the Fund ID, so the adapter omits the Fund itself and avoids recursive valuation.

## Runtime Evidence

- Unified 1Ex account discovery includes the adapter AccountID.
- Direct and unified reads each returned five stable product and position IDs.
- The Fund's immediate sample returned USD, five positions, no unpriced rows, and positive equity; the Fund now has one NAV record.
- Readback confirms source enabled/authenticated, Fund enabled/private/non-subscribable, and no self Fund row in the adapter's five underlying positions.

## Security And Rollback

The runtime seed, both bearer types, and decrypted environment never entered the repository or task artifacts. Short-lived signing material used root-owned `/run` files removed at shell exit. If a future source/Fund issue requires rollback, disable the Fund before attempting source removal; no Acorn configuration changed in this task.

## Delivery Lifecycle

Implementation PR [#163](https://github.com/Thrimbda/dotfiles/pull/163) merged at `2026-08-18T16:02:49Z` as `407b634d`. GitHub reported no required checks and no reviews. The implementation worktree is cleaned up after this closeout evidence is merged.

## Evidence

- Design: `docs/rfc.md`
- Design review: `docs/review-rfc.md`
- Verification: `docs/test-report.md`
- Change review: `docs/review-change.md`
- Sample residual trace: `docs/research.md`
