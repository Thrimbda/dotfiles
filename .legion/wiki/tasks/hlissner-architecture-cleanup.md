# Hlissner-aligned Dotfiles Architecture Cleanup

## Metadata

- `task-id`: `hlissner-architecture-cleanup`
- `status`: `active`
- `risk`: `high`
- `schema-version`: `2026-05-12`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- This task studied the current repository and hlissner/dotfiles, then delivered a bounded architecture cleanup that preserves the existing hlissner-style custom flake/module/host framework.
- The implementation centralizes shared Wayland/QT desktop env constants, reuses the platform-aware env helper, removes an unused desktop helper, and normalizes exact-equivalent host-local user-home paths.
- It intentionally does not introduce new public opencode/autossh/cloudflared modules, does not change flake inputs/lock, and does not change Cloudflare/secret/tunnel/port boundaries.
- Local validation passed through `git diff --check`, flake host metadata eval, generated env/path evals, helper non-import check, and Axiom toplevel dry-run.
- PR delivery is required but auto-merge is explicitly disabled per user request.

## Reusable Decisions

- When doing behavior-preserving dotfiles architecture cleanup, copy hlissner-style organization principles rather than upstream Linux-only implementation details.
- Internal helper files under `modules/` should be `_`-prefixed or otherwise skipped by recursive module discovery.
- Service/path normalization is acceptable only when evaluated values remain equivalent and sensitive ports, tunnel IDs, hostnames, bind hosts and secret paths do not change.
- Do not promote host-local opencode/autossh/cloudflared snippets into reusable modules during a cleanup task unless a separate RFC explicitly scopes the new public contract.

## Related Raw Sources

- `plan`: `.legion/tasks/hlissner-architecture-cleanup/plan.md`
- `log`: `.legion/tasks/hlissner-architecture-cleanup/log.md`
- `tasks`: `.legion/tasks/hlissner-architecture-cleanup/tasks.md`
- `research`: `.legion/tasks/hlissner-architecture-cleanup/docs/research.md`
- `rfc`: `.legion/tasks/hlissner-architecture-cleanup/docs/rfc.md`
- `review-rfc`: `.legion/tasks/hlissner-architecture-cleanup/docs/review-rfc.md`
- `test-report`: `.legion/tasks/hlissner-architecture-cleanup/docs/test-report.md`
- `review-change`: `.legion/tasks/hlissner-architecture-cleanup/docs/review-change.md`
- `report`: `.legion/tasks/hlissner-architecture-cleanup/docs/report-walkthrough.md`
