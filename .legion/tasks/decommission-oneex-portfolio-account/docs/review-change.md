# Change Review: Minimal 1Ex Portfolio Adapter Undeployment

## Findings

1. **No blocking implementation finding.** The complete tracked production change at `b1049dbd936191b8a9d4ada8687639fae94b1137` is the one-line removal of `./modules/oneex-portfolio-adapter.nix` from `hosts/acorn/default.nix`; module, package, secret, agenix, and other production files are unchanged.
2. **Evaluation matches intent.** Axiom no-cache results are service=`false`, vhost=`false`, secret=`true`, and the full Acorn toplevel returned a `drvPath` (`test-report.md`).
3. **The runtime secret intentionally remains.** `modules/agenix.nix:58-68` imports it independently; no secret value was read, and its presence is not an undeployment failure.
4. **Delivery remains blocked by stale evidence.** The branch is `0/1` versus `origin/master`, whose Acorn-changing commit touches the import list; rebase and full candidate reverification are mandatory.

## Verdict

**PASS** for implementation correctness, scope compliance, and security review. This does not approve merge, build, activation, or closeout from the stale candidate.

## Residual Risk And Pending Work

- Until activation, the loaded but `inactive/dead` unit may return after reboot or manual start.
- Rebase onto current `origin/master`; rerun exact-diff, syntax, no-cache service/vhost/secret, toplevel, and pre-deployment state checks on Axiom.
- After merge, refresh Axiom, deploy with the exact `rfc.md` command, stop on any build/transfer/activation failure, and never build on Acorn.
- Verify post-activation unit/process/TCP `8090`/active-vhost absence plus failed-unit and unrelated-service health; the runtime secret remains expected.

No external account/browser/auth state was mutated. References: `rfc.md`, `test-report.md`, `review-rfc.md`, `research.md`, `../plan.md`, `../log.md`.
