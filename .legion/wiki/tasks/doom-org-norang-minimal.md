# Doom Org/Norang Minimal

## Metadata

- `task-id`: `doom-org-norang-minimal`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task narrowed the Doom private config to an Org/Norang profile centered on `bh-org.el`. The implementation was completed through PR [#1](https://github.com/Thrimbda/doom-c1/pull/1), merged to `master` as commit `507d5924f966a8da3e8736cf87f5d630da7cd86f`, and the active `/Users/c1/.config/doom` worktree was fast-forwarded to that result.

The current effective design keeps basic completion/UI/file-management, macOS/tty support, `emacs-lisp`, `(org +crypt)`, `sh`, and default bindings. `packages.el` is reduced to `mixed-pitch`, `org-appear`, and `rime`; `config.el` no longer references removed packages/modules such as `org-pretty-table`, `org-books`, or `projectile`.

`bh-org.el` compatibility fixes were intentionally narrow: `org-switchb` replaces obsolete `org-iswitchb`, `cl-incf` replaces `incf`, unsupported Babel language entries were removed, and the missing clock sound path is guarded.

Verification passed in both the isolated Doom worktree and the final active config with `doom sync`, `doom doctor`, `check-parens`, and an Emacs batch load of `bh-org.el`. The remaining facts are environment/manual follow-ups: the local machine has no GPG secret key for `F0B66B40`, and GUI Emacs interaction was not smoked by the agent.

## Reusable Decisions

- For a Doom profile intended only for Org/Norang, keep the private config small: Org plus the minimum editor/runtime support needed to load the workflow, not general-purpose IDE, VCS, RSS, terminal, or multi-language modules.
- Preserve `bh-org.el` workflow semantics when modernizing compatibility; prefer small API substitutions and load guards over rewriting norang task/project logic.
- Validate an isolated Doom private config with `DOOMDIR=<worktree> doom sync`, `DOOMDIR=<worktree> doom doctor`, parenthesis checks, and an Emacs batch load of the workflow file before touching the active `~/.config/doom`.

## Related Raw Sources

- `plan`: `.legion/tasks/doom-org-norang-minimal/plan.md`
- `log`: `.legion/tasks/doom-org-norang-minimal/log.md`
- `tasks`: `.legion/tasks/doom-org-norang-minimal/tasks.md`
- `rfc`: `.legion/tasks/doom-org-norang-minimal/docs/rfc.md`
- `test-report`: `.legion/tasks/doom-org-norang-minimal/docs/test-report.md`
- `review-change`: `.legion/tasks/doom-org-norang-minimal/docs/review-change.md`
- `report`: `.legion/tasks/doom-org-norang-minimal/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/doom-org-norang-minimal/docs/pr-body.md`

## Notes

- PR lifecycle completed: PR [#1](https://github.com/Thrimbda/doom-c1/pull/1) merged, remote/local temporary branch deleted, implementation worktree removed, and active `/Users/c1/.config/doom` refreshed.
- HTML walkthrough render handoff is artifact-only because no Pages/CI rendered preview target exists; local artifact path is `.legion/tasks/doom-org-norang-minimal/docs/report-walkthrough.html`.
- Actual use of `org-crypt` requires importing or replacing the missing `F0B66B40` GPG secret key.
