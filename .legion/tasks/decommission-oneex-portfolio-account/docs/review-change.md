# Change Review: Minimal 1Ex Portfolio Adapter Undeployment

## Findings

1. **No blocking correctness, scope, or security finding.** Rebased candidate `da08cfbcca046848bdf09bce85caf3f1ccafd9ef` is one commit ahead of local `origin/master` at `a291a95b9def6ec3b29d66b8bde3c42973bc63dd`, with that exact upstream revision as its merge base. The prior stale-base blocker is closed.
2. **Upstream Cybion changes are preserved.** `hosts/acorn/default.nix:9` still imports `./modules/cybion.nix`; `hosts/acorn/modules/cybion.nix` and the upstream `hosts/acorn/modules/platform.nix` change have no diff from `origin/master`. The rebase did not retire or alter Cybion.
3. **Production scope remains exactly one line.** Excluding task evidence under `.legion`, `origin/master...HEAD` changes only `hosts/acorn/default.nix` with `0` additions and `1` deletion: `./modules/oneex-portfolio-adapter.nix`. The adapter module, package snapshot, complete Acorn secrets directory, and global agenix module are unchanged (`test-report.md:31-58`).
4. **Evaluation matches the intended undeployment.** The removed module is the only production Nix path that declares the adapter service and vhost or evaluates its module-local package derivation. Rebased Axiom no-cache evaluation reports service=`false`, vhost=`false`, secret=`true`; full toplevel evaluation returns a new `drvPath` (`test-report.md:60-66`).
5. **The global runtime age secret intentionally remains.** `modules/agenix.nix:58-68` still imports the unchanged declaration from `hosts/acorn/secrets/secrets.nix:12`. No secret value was read or printed. Removing the adapter module also removes its service-specific owner/group/mode overrides; retention under the global/default age configuration remains the explicitly reviewed security residual.

## Verdict

**PASS** for the rebased candidate's implementation correctness, production scope, upstream preservation, and security review.

The candidate is ready for merge/deployment workflow. This review does not claim that the closure has been built, Acorn has been activated, or final runtime acceptance has passed.

## Security Lens

**Applied** because retained credential material is in scope. The candidate modifies no ciphertext, secret declaration, adapter package/module, credential consumer outside the removed import, or external account/browser/auth state. Verification inspected only the age secret attribute's presence and disclosed no secret content. No exploitable or unreviewed trust-boundary issue was found.

## Residual Risk And Pending Work

- Until activation, the loaded but `inactive/dead` unit may return after reboot or manual start.
- The dormant adapter module, package snapshot, ciphertext, globally generated runtime secret, old generations, and store paths remain by design and could support later rollback or accidental reintroduction.
- After merge, refresh Axiom, deploy with the exact `rfc.md` command, stop on any build/transfer/activation failure, and never build on Acorn.
- Verify post-activation unit/process/TCP `8090`/active-vhost absence plus failed-unit and unrelated-service health; the runtime secret remains expected.

## Blockers

**Review blockers: None.**

Merge, Axiom closure build/remote activation, and post-activation runtime/health verification remain pending completion gates, not defects in the rebased candidate.

References: `rfc.md`, `test-report.md`, `review-rfc.md`, `research.md`, `../plan.md`, `../log.md`.
