# Workspace Non-Sensitive Checkpoint 2026-08-19

## Metadata

- `task-id`: `workspace-nonsensitive-checkpoint-2026-08-19`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's declarative root, EFI, and swap devices now use `nixos-2t`, `AXIOM2T`, and `swap-2t` on the KIOXIA 2TB disk.
- Local password, API-key, private-key, nested-worktree, and mutable Fcitx paths remained outside Git.
- Auth-mini-gateway pin evidence and the hey/c1ctl capability inventory were preserved as reviewed non-sensitive documentation.
- Initial review rejected three unrelated regressions; the final checkpoint preserves Axiom's single idle owner and the merged #166/#167/#168 evidence.

## Reusable Decisions

- A broad workspace checkpoint still requires correctness and current-truth review; explicit "commit everything non-sensitive" does not make runtime or audit regressions safe to merge.
- Import untracked content through an explicit safe-file list and verify the staged snapshot against known credential paths and token patterns.
- Preserve locally required credential files without adding them to Git or deleting them during worktree cleanup.

## Related Raw Sources

- `plan`: `.legion/tasks/workspace-nonsensitive-checkpoint-2026-08-19/plan.md`
- `log`: `.legion/tasks/workspace-nonsensitive-checkpoint-2026-08-19/log.md`
- `tasks`: `.legion/tasks/workspace-nonsensitive-checkpoint-2026-08-19/tasks.md`
- `reviews`: `.legion/tasks/workspace-nonsensitive-checkpoint-2026-08-19/docs/review-change.md`
- `report`: `.legion/tasks/workspace-nonsensitive-checkpoint-2026-08-19/docs/report-walkthrough.md`
