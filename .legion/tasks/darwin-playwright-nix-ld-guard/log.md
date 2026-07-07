# Darwin Playwright Nix-LD Guard Log

## 2026-07-08

- 用户在 `charlie` 上运行 `sudo darwin-rebuild switch --flake .#charlie`，eval 失败于 `modules/dev/playwright.nix` 定义了 nix-darwin 不存在的 `programs.nix-ld` option。
- 入口判断：Legion-managed 仓库，修改型开发任务，进入 `legion-workflow` 与 `git-worktree-pr` envelope。
- 选择 task id：`darwin-playwright-nix-ld-guard`。
- 风险判断：低风险局部平台 guard 修复，走 design-lite。
- 实现：在 `modules/dev/playwright.nix` 中新增 `hasNixLd` option-existence guard，并用 `optionalAttrs hasNixLd` 生成 `programs.nix-ld.libraries`，避免 nix-darwin 看到不存在的 option。
- 验证：`darwin-rebuild build --flake .#charlie` 与 `nix build .#darwinConfigurations.charlie.system` 均通过；`nix eval .#nixosConfigurations.axiom.config.programs.nix-ld.libraries --apply builtins.length` 返回 `56`；生成的 charlie autossh plist 保持 `c1@8.159.128.125`。
- Review：`docs/review-change.md` 判定 PASS。变更范围仅限 Playwright module guard，未触发安全视角。
- Walkthrough：生成 `docs/report-walkthrough.html`、`docs/report-walkthrough.md` 与 `docs/pr-body.md`。HTML 选择 artifact/local preview，不发布 Pages。
- Report QA：`rg -n '—|#000|#fff|background-clip|border-left|border-right|https?://|@import' docs/report-walkthrough.html` 返回无匹配。
- Wiki：新增 task summary，并把共享 Playwright 模块的 `programs.nix-ld` option-existence guard 结论提升到 wiki decisions/patterns。
