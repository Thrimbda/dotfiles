# dotfiles-prune-host-frameworks

## Metadata

- `task-id`: `dotfiles-prune-host-frameworks`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Closed raw Legion task evidence was pruned after preserving the wiki current-truth layer, and the stale root README was removed. Axiom and Acorn now use manifest-sized host defaults: reusable mechanics stay in focused shared modules, while concrete topology and policy live in host-local modules. A one-off package-module inventory records later cleanup candidates without changing those modules.

## Reusable Decisions

- Keep shared Nix modules limited to proven mechanics; keep domains, addresses, ports and single-host policy in host-local composition.
- When splitting ordered Nix lists across modules, compare the evaluated order and use adjacent private package helpers rather than exposing a public option only to preserve placement.
- Closed raw task directories may be removed once their durable wiki summaries exist; historical raw links resolve through Git history.

## Related Raw Sources

- `plan`: `.legion/tasks/dotfiles-prune-host-frameworks/plan.md`
- `log`: `.legion/tasks/dotfiles-prune-host-frameworks/log.md`
- `tasks`: `.legion/tasks/dotfiles-prune-host-frameworks/tasks.md`
- `rfc`: `.legion/tasks/dotfiles-prune-host-frameworks/docs/rfc.md`
- `reviews`: `.legion/tasks/dotfiles-prune-host-frameworks/docs/review-rfc.md`, `.legion/tasks/dotfiles-prune-host-frameworks/docs/review-change.md`
- `verification`: `.legion/tasks/dotfiles-prune-host-frameworks/docs/test-report.md`
- `report`: `.legion/tasks/dotfiles-prune-host-frameworks/docs/report-walkthrough.md`
