## Summary

- Register the deployed 1Ex portfolio adapter as the enabled `1Ex Portfolio Adapter` Custom Account Source.
- Create the enabled private USD `My Portfolio` Trading Fund backed by that source, with subscriptions closed.
- Reuse the already deployed exclusion UUID as the Fund ID so the adapter excludes its own portfolio Fund without an Acorn redeploy.

## Verification

- Authenticated preflight found no prior custom source, no `My Portfolio` Fund, and no exclusion-ID collision.
- Unified discovery exposes the adapter AccountID; direct and unified reads expose the same five stable product and position IDs.
- Fund sample: USD, five positions, no unpriced rows, positive equity, and one recorded NAV.
- Final readback: source enabled with stored header; Fund enabled/private/non-subscribable; direct adapter output excludes the enabled Fund.

## Operational Note

The upstream auth/Fund path can fail transiently and the adapter fails closed with `502`. The first sample's error status was not retained, but failure cleanup disabled the new Fund; one non-retried disabled-state sample succeeded before the final enable.
