# Deployment Walkthrough

## Mode

`implementation`

## Delivered Change

- Adds a pinned Rust adapter package and the minimal Acorn module required to run it as `oneex-portfolio-adapter`.
- Stores the runtime identity only in an Acorn age secret and keeps the process on `127.0.0.1:8090`.
- Publishes `https://1ex-portfolio.0xc1.wang` through nginx with Cloudflare DNS-01 ACME and a DNS-only Cloudflare A record.
- Raises only the adapter's upstream read timeout from 4.5 to 5.8 seconds, matching observed live Fund latency.

## Runtime Outcome

- Acorn was built on the local build host and remotely switched with the required `--build-host localhost` command.
- The adapter and nginx are active; only the adapter's loopback socket listens on port 8090.
- ACME completed successfully. Public DNS resolves to `8.159.128.125`, an unauthenticated ordinary-hostname request returns `401`, and authenticated direct-SNI accounts and positions requests return `200` with five live positions.

## Review Outcome

`docs/review-change.md` records a PASS after scope, correctness, provenance, and security review. The age ciphertext is the only tracked secret material, the bearer remains the adapter's existing 43-character HMAC-derived value, and the service runs without ambient capabilities or root privileges.

## Delivery Lifecycle

Implementation PR [#161](https://github.com/Thrimbda/dotfiles/pull/161) merged at `2026-08-18T14:21:18Z` as `670f844c`. GitHub reported no required checks and no review gate. The implementation worktree is cleaned up after this closeout evidence is merged.

## Operational Boundary

The external auth and 1Ex Fund endpoints can fail transiently. The adapter returns `502` rather than a partial result; callers that need higher availability should retry. Rollback is a prior Acorn NixOS generation followed by A-record removal only if the endpoint is retired.

## Evidence

- Design: `docs/rfc.md`
- RFC review: `docs/review-rfc.md`
- Verification: `docs/test-report.md`
- Change review: `docs/review-change.md`
