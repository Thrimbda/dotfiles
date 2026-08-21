# Research Notes

## Problem Restatement

- The active Acorn `oneex-portfolio-adapter` binary returns `502` for the registered Custom Account Source even though its Fund remains readable and has positive assets.
- The active binary does not contain the `redirect_uri` login field. A valid device session without that field has `aud=auth.ntnl.io`, while 1Exchange requires `aud=1ex.ntnl.io` and rejects it with `401 invalid auth-mini access token`.
- `My Portfolio` has positive total assets, zero investors, and zero total shares. Its unit price therefore correctly projects as `1` until a one-time initial owner investment issues shares.

## Relevant Entry Points

- `packages/oneex-portfolio-adapter/vendor/src/main.rs:328-383` creates the device session and fetches 1Exchange funds and balances. The tracked source already sends `redirect_uri` in the verify request at lines 353-357.
- `hosts/acorn/modules/oneex-portfolio-adapter.nix:6-19,36-61` builds the vendored adapter and defines the hardened Acorn service. The active executable is an earlier closure despite the tracked source containing the fix.
- `.legion/tasks/register-oneex-portfolio-fund/docs/test-report.md` records the original source/Fund binding, first sample, and recursion exclusion.
- `https://github.com/No-Trade-No-Life/1Exchange/blob/9416adfed9d5f221aa2a581bcb4f5328b5eb0a23/src/auth.rs` requires the `1ex.ntnl.io` audience.
- `https://github.com/zccz14/auth-mini/blob/22ac651e2c3340f4a0f925af048fe9a6b5c7918d/rust-backend/src/ed25519.rs` accepts `redirect_uri` on device-session verification and mints the corresponding audience.

## Existing Conventions

- The adapter fails closed: an upstream auth, read, mapping, timeout, or logout failure returns `502`; it must not emit partial or zero positions.
- The source has a fixed self-Fund exclusion ID, so the portfolio Fund cannot recursively value itself.
- Acorn builds and activation must run from Axiom with the prescribed `nixos-rebuild switch` command. Acorn must never build its own closure.
- Runtime seed material, bearer tokens, and decrypted environment content stay in protected Acorn runtime memory or temporary `/run` files and are never printed or committed.

## Historical Decisions

- Upstream adapter commit `8dcf21f` added the audience request; the dotfiles vendor already contains that implementation.
- The original deployment task verified five positions and a positive initial Fund sample. The current service closure is older than the tracked vendor behavior.
- The Fund registration task intentionally created a private, non-subscribable personal Fund but did not create an investor or cash flow. That is why it has no issued units.

## Constraints And Non-goals

- Deploy only from a clean dotfiles worktree on Axiom. Do not modify auth-mini, 1Exchange, the source/Fund binding, credentials, or historical performance.
- Do not create any Fund accounting event until a new live source read and immediate Fund sample both succeed.
- Do not automatically repair, delete, or retry an accounting event if the post-write sample fails.

## Risks And Pitfalls

- A rollout that does not activate the current binary leaves the source at `502`; the accounting step must not start.
- A duplicate initial-investment request mints duplicate units. Require zero investors and zero shares immediately before the single write.
- The initial investment temporarily adds the baseline to the reducer state. A successful immediate trading NAV sample is required immediately afterward to replace that interim total with the actual account value.
- Axiom's Nix database marks the prior adapter output as live although its store directory is missing. Both supported repair commands are unavailable through its daemon, and normal deletion correctly refuses a live path. The old output must not be faked or force-deleted.
- Account values are live. The only valid baseline is the equity returned by the same-run pre-write Fund sample, not an earlier displayed amount.

## Remaining Verification

- [x] The merged Acorn deployment activated a fresh `audience-rebuild1` adapter output.
- [x] The Custom Account Source returned HTTP `200` with six positions and no self-Fund row.
- [x] The pre-write sample was positive and fully priced; one owner profile plus one initial cash-flow event were created.
- [x] The post-write sample initially returned `502`; after source recovery and explicit user approval, one corrective sample restored `total_assets / total_share = unit_price`.

## Outcome

- The earlier missing-store-path residual was not a source-code dependency. The user command had run from a main worktree that predated merged PR #184. Refreshing that worktree to `af799348` selected the fresh output and allowed the prescribed deployment to complete.
- `My Portfolio` now has one active owner investor and positive units. Its latest corrected equity, total assets, and total shares are all `28977.0677876943`; its unit price is `1.0` at that baseline and will move with future enabled Fund samples.

## References

- Task contract: `../plan.md`
- Original source/Fund evidence: `.legion/tasks/register-oneex-portfolio-fund/docs/test-report.md`
- Adapter deployment module: `hosts/acorn/modules/oneex-portfolio-adapter.nix`
- Adapter implementation: `packages/oneex-portfolio-adapter/vendor/src/main.rs`
