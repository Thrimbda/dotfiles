## Summary

- Pin auth-mini to upstream release `latest-2026-07-12`.
- Replace the Linux release archive hash with the verified upstream digest.
- Keep the production change to the package version and hash only.

## RFC

No RFC was produced, by explicit user request. The task plan treats deployment redesign as out of scope for this two-line pin update.

## Verification

- `git diff --check` — PASS.
- `nix build --no-link .#packages.x86_64-linux.auth-mini` — PASS.
- `nix build --no-link .#nixosConfigurations.acorn.config.system.build.toplevel` — PASS.
- Evaluation and closure checks confirmed version `latest-2026-07-12`, the configured hash, and use of the updated package by Acorn.
- The release asset digest and independent URL prefetch matched the configured hash for upstream merge `9560660a51ee0e0b0a538e36c0b2883b16281eff`.

## Review

PASS. No blocking correctness, scope, maintainability, or security findings; ready for delivery and PR merge.

## Evidence

- `.legion/tasks/auth-mini-upstream-release-pin/plan.md`
- `.legion/tasks/auth-mini-upstream-release-pin/docs/test-report.md`
- `.legion/tasks/auth-mini-upstream-release-pin/docs/review-change.md`
- `.legion/tasks/auth-mini-upstream-release-pin/docs/report-walkthrough.md`

## Risk

The existing mutable `latest` URL remains bounded by the fixed-output hash, so upstream drift fails closed.
