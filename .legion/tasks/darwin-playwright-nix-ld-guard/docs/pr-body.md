# Implementation Review

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 `charlie` nix-darwin eval 失败：Darwin 不再评估 Linux-only 的 `programs.nix-ld` option。
- `modules/dev/playwright.nix` 改为通过 `hasNixLd` 判断 option 是否存在，再用 `optionalAttrs hasNixLd` 生成 nix-ld libraries。
- `darwin-rebuild build --flake .#charlie` 和显式 `nix build .#darwinConfigurations.charlie.system` 均已通过。

## 范围

**In scope**

- `modules/dev/playwright.nix` 的 nix-ld option guard。
- Legion task 文档、验证报告、review 结论和 walkthrough。

**Out of scope**

- 不升级 flake inputs、nixpkgs 或 nix-darwin。
- 不重构 dev module 层。
- 不修改 autossh 配置或运行态 LaunchAgent。
- 不处理后续 `darwin-rebuild switch` activation 阶段可能暴露的独立问题。

## 主要改动

- 新增 `hasNixLd = builtins.hasAttr "programs" options && builtins.hasAttr "nix-ld" options.programs;`
- 将 `programs.nix-ld.libraries` attrset 从 `mkIf (!isDarwin)` 改为 `optionalAttrs hasNixLd`

## 验证与审查

- 验证: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/test-report.md`
- 变更审查: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/review-change.md`
- Design-lite: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/rfc.md`

验证摘要：

- `nix-instantiate --parse modules/dev/playwright.nix` 通过。
- `darwin-rebuild build --flake .#charlie` 通过。
- `nix build .#darwinConfigurations.charlie.system` 通过。
- `nix eval .#nixosConfigurations.axiom.config.programs.nix-ld.libraries --apply builtins.length` 返回 `56`。
- `git diff --check` 通过。
- `review-change` PASS。

## 风险与限制

- 本 PR 修复 eval/build blocker，不直接执行 `sudo darwin-rebuild switch`。
- 若合并后 switch 暴露 activation-time 问题，应单独处理，除非证据指回本 guard。

## 评审重点

- [ ] 变更是否符合 task contract 与 scope？
- [ ] `optionalAttrs hasNixLd` 是否正确避免 nix-darwin unknown option？
- [ ] Darwin build 和 explicit nix build 证据是否足够？
- [ ] Linux/Axiom Playwright nix-ld runtime intent 是否保留？

## 证据链接

- plan: `.legion/tasks/darwin-playwright-nix-ld-guard/plan.md`
- rfc: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/rfc.md`
- test-report: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/test-report.md`
- review-change: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/review-change.md`
- report-walkthrough: `.legion/tasks/darwin-playwright-nix-ld-guard/docs/report-walkthrough.md`
