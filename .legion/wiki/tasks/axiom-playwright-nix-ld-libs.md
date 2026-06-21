# axiom-playwright-nix-ld-libs

## Metadata

- `task-id`: `axiom-playwright-nix-ld-libs`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-06-21`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- This task fixes Axiom's npm/npx Playwright Chromium startup failure caused by missing `libglib-2.0.so.0` and related runtime libraries on NixOS.
- The current effective implementation keeps `pkgs.playwright-test` and adds Linux-only `programs.nix-ld.libraries` entries from `modules/dev/playwright.nix`.
- Verification passed for the system Playwright wrapper, npm Playwright `1.61.0` downloaded Chromium launch, Axiom Nix eval, and Axiom dry-run build planning.
- PR lifecycle is still active until the branch is pushed, PR checks/review are resolved, and the PR reaches a terminal state.

## Reusable Decisions

- Prefer the Nix-packaged Playwright wrapper as baseline, but support npm/npx Playwright browser binaries by exposing required runtime libraries through `nix-ld`.
- For Playwright on NixOS, test both wrapper and npm/npx downloaded browser paths.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-playwright-nix-ld-libs/plan.md`
- `log`: `.legion/tasks/axiom-playwright-nix-ld-libs/log.md`
- `tasks`: `.legion/tasks/axiom-playwright-nix-ld-libs/tasks.md`
- `rfc`: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/rfc.md`
- `test-report`: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/test-report.md`
- `review-change`: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/review-change.md`
- `render-handoff`: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/render-handoff.md`
- `report`: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/pr-body.md`

## Notes

- `nixos-rebuild switch` was intentionally not run during verification.
- The live host receives the persistent fix after the merged change is switched on Axiom.
