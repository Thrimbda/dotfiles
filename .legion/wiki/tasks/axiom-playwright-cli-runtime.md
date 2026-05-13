# Axiom Playwright CLI Runtime

## Metadata

- `task-id`: `axiom-playwright-cli-runtime`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task makes Playwright CLI available on the `axiom` NixOS host through the existing declarative development module. The implementation enables `modules.dev.playwright` in `hosts/axiom/default.nix` rather than adding project-level npm dependencies or mutable browser downloads.

The current effective conclusion is that `pkgs.playwright-test` is the repository-owned Playwright CLI package. Its wrapper runs `playwright`, exposes version `1.56.1`, and defaults `PLAYWRIGHT_BROWSERS_PATH` to the Nix-provided `playwright-browsers` package.

Verification confirms the Axiom option evaluates to `true`, the evaluated `users.users.c1.packages` contains `playwright-test`, the `pw` alias resolves to `playwright`, the package wrapper includes browser path wiring, and the Axiom toplevel dry-run succeeds.

Runtime browser launch remains a post-switch smoke check because this task intentionally avoids live `nixos-rebuild switch`.

## Reusable Decisions

- For Axiom Playwright tooling, prefer enabling the existing `modules.dev.playwright` module over manually adding `pkgs.playwright-test` to host-local packages.
- Treat the Nix package wrapper's `PLAYWRIGHT_BROWSERS_PATH` default to `playwright-browsers` as the browser dependency integration surface; do not add mutable Playwright browser download flows unless a future task explicitly changes that boundary.
- Validate Playwright installation through the evaluated host option, evaluated user package closure, CLI version, wrapper browser path, and an Axiom toplevel dry-run.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-playwright-cli-runtime/plan.md`
- `log`: `.legion/tasks/axiom-playwright-cli-runtime/log.md`
- `tasks`: `.legion/tasks/axiom-playwright-cli-runtime/tasks.md`
- `test-report`: `.legion/tasks/axiom-playwright-cli-runtime/docs/test-report.md`
- `review`: `.legion/tasks/axiom-playwright-cli-runtime/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-playwright-cli-runtime/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-playwright-cli-runtime/docs/pr-body.md`

## Notes

- After this branch is applied to Axiom, switch the host configuration and run a live Playwright browser smoke test in the graphical session.
