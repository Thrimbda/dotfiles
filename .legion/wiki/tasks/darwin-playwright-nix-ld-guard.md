# Darwin Playwright Nix-LD Guard

## Metadata

- `task-id`: `darwin-playwright-nix-ld-guard`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-07-05-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

`charlie` 的 nix-darwin eval 失败是因为共享的 `modules/dev/playwright.nix` 在 Darwin 模块图里生成了 NixOS-only 的 `programs.nix-ld` option。修复后，模块先探测 `options.programs.nix-ld` 是否存在，再用 `optionalAttrs` 生成 `programs.nix-ld.libraries`。

当前有效结论是：Playwright 的 Linux/npm browser runtime 仍通过 `nix-ld` libraries 支持；Darwin host 不再看到该 unknown option。`darwin-rebuild build --flake .#charlie` 和显式 `nix build .#darwinConfigurations.charlie.system` 均已通过。

Linux/Axiom 侧的意图通过 `nix eval .#nixosConfigurations.axiom.config.programs.nix-ld.libraries --apply builtins.length` 保留为 56 项。

## Reusable Decisions

- NixOS-only module options in shared Linux/Darwin dev modules should be guarded by option existence before generating the attrset.
- Do not rely on `mkIf` around an unknown option as a nix-darwin compatibility boundary.
- For this repo's Playwright runtime, verify Darwin build safety and Linux `nix-ld` intent separately.

## Related Raw Sources

- `plan`: `.legion/tasks/darwin-playwright-nix-ld-guard/plan.md`
- `log`: `.legion/tasks/darwin-playwright-nix-ld-guard/log.md`
- `tasks`: `.legion/tasks/darwin-playwright-nix-ld-guard/tasks.md`
- `rfc`: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/rfc.md`
- `test-report`: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/test-report.md`
- `review-change`: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/review-change.md`
- `report`: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/pr-body.md`

## Notes

- `sudo darwin-rebuild switch --flake .#charlie` remains the post-merge deployment step.
