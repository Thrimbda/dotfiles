# Review Change: Rollout Audience-Bound Gateway User IDs

> **Review stage:** `review-change`
> **Date:** 2026-07-31
> **Reviewed:** `plan.md`, `docs/test-report.md`, and the full worktree diff
> **Security lens:** Applied (authentication authorization, identity allowlist, encrypted secrets, production deployment boundary)

## Verdict

**PASS for merge.**

The diff is narrowly scoped to the reviewed audience-bound gateway package and the two host-local encrypted authorization environments. It does not expose the supplied user ID or any gateway cookie secret in plaintext, does not alter auth-mini, and does not change nginx, FRP, firewall, protected-upstream, or cookie topology.

## Blocking Findings

None.

## Security and Correctness Review

| Boundary | Result |
|---|---|
| Package provenance | `packages/auth-mini-gateway/default.nix` pins the merged upstream commit `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4` with explicit fixed-output source and Cargo hashes. |
| Authorization migration | Both encrypted env files were transformed and re-decrypted successfully. Assertions prove the previous cookie secret was preserved, the supplied exact user ID is the only allowlist entry, and no nonempty `ALLOW_EMAILS` remains. |
| Secret handling | No plaintext gateway secret or supplied user ID appears in Nix, task docs, PR evidence, or the worktree. Repository scan found no plaintext UID match. |
| Runtime permissions | Axiom and Acorn agenix metadata still evaluate to owner `auth-mini-gateway` and mode `0400`. |
| Scope | No unrelated host, auth-mini, nginx, FRP, Cloudflare, firewall, or session-database changes are present. |
| Rollback | Rollback is a normal dotfiles revert plus host switch. The gateway package and secret changes are small and independently recoverable; old sessions may still require bounded re-login under the upstream audience contract. |

## Non-blocking Residuals

1. Live Axiom and Acorn switches are intentionally post-merge deployment steps in the task contract.
2. Credential-bearing browser login cannot be proven by repository automation without modifying production auth-mini data; it remains the user's post-deploy smoke check.
3. Existing sessions can remain usable only until their recorded refresh boundary; legacy audience rejection then requires re-login. This is the approved migration behavior.

## Evidence

`docs/test-report.md` records package build success with 119 library + 50 proxy integration tests, secret decrypt/transform/re-encrypt/decrypt assertions for both hosts, agenix mode/owner evaluation, plaintext UID scan, and `git diff --check`.

Ready to merge, then deploy Axiom and Acorn from the refreshed main workspace.
