# RFC: Minimal 1Ex Portfolio Adapter Undeployment

> **Status**: Design approved; final delivery blocked pending rebase and reverification.

## Decision

Remove exactly this one line from `hosts/acorn/default.nix`:
```diff
-    ./modules/oneex-portfolio-adapter.nix
```
Make no other production change. This removes the adapter service, user/group, nginx vhost, ACME contribution, and package evaluation from the replacement Acorn configuration.
Because `modules/agenix.nix:58-68` globally imports host secret declarations, the runtime `age.secrets.oneex-portfolio-adapter-env` intentionally remains and is not an undeployment failure.

## Scope

Non-goals: edit/delete the dormant adapter module, package, ciphertext, secret declaration/runtime secret, or task helpers; mutate external 1Exchange, auth-mini, browser, DNS, Git history, generations, or store state; add a mask/manual unit state; or evaluate/build locally on Acorn.
The abandoned browser/full-account/mask design was superseded with no external mutation, and the task-created mask was cleaned.

## Deployment

Run all validation and builds on Axiom. Immediately before deployment, require the Acorn service to remain `inactive/dead`; active or restarting drift is a hard stop.
From refreshed merged code on Axiom, run exactly:
```bash
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```
`--build-host localhost` must mean Axiom. On build, closure-transfer, or activation failure, stop and report; never evaluate/build on Acorn or use an interim service restart.
After activation, require adapter unit, process, TCP `8090`, and active nginx vhost/proxy absence; no new failed unit; and continued health of the RFC-listed unrelated services. Do not read the retained secret.

## Rollback

Restore `./modules/oneex-portfolio-adapter.nix` through reviewed Git, merge, refresh Axiom, and rerun the same Axiom-to-Acorn deployment command. Do not create partial manual host state.

## Pending And References

The candidate is one Acorn-changing commit behind `origin/master`; rebase while preserving upstream changes, then rerun exact-diff, syntax, focused no-cache evaluation, and full toplevel evaluation before merge.
Merge, Axiom refresh, activation, and post-activation runtime/health checks remain pending. Evidence: `research.md`, `test-report.md`, `review-rfc.md`, `review-change.md`; contract/history: `../plan.md`, `../log.md`.
