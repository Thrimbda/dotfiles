## Summary

- prune closed Legion raw tasks from 145 directories to the current task only while retaining the wiki knowledge layer
- shrink Axiom and Acorn defaults to 179-line and 45-line manifests using shared mechanics plus host-local composition
- delete the stale root README and inventory one-off package modules without broad package cleanup
- preserve merged Qwen controls, warning migrations, topology, secrets, package order and generated service behavior

## Verification

- one-task whitelist, wiki-retention and protected-file checks
- `nix-instantiate --parse` for all 22 changed Nix files
- Axiom, Acorn and Charlie candidate derivation evaluation
- normalized baseline/candidate snapshots for moved service, ingress, package and host-policy surfaces
- baseline and candidate Axiom dry-runs: 28 derivations each
- full flake check: identical pre-existing `apps.install` schema failure on baseline and candidate

## Review

- correctness, scope and maintainability review: PASS
- security lens for auth, ingress, reverse SSH, secrets, RustDesk and Qwen sudo boundaries: PASS
- no live deployment; no Acorn build, switch or deployment

## Evidence

- `.legion/tasks/dotfiles-prune-host-frameworks/docs/test-report.md`
- `.legion/tasks/dotfiles-prune-host-frameworks/docs/review-change.md`
- `.legion/tasks/dotfiles-prune-host-frameworks/docs/report-walkthrough.md`
