# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本 PR 修复 `charlie` nix-darwin eval 失败：Darwin 不再看到不存在的 `programs.nix-ld` option。
- 实现只改 `modules/dev/playwright.nix`，用 `options` 判断 `programs.nix-ld` 是否存在，再通过 `optionalAttrs hasNixLd` 生成 Linux/NixOS 专用 library list。
- `darwin-rebuild build --flake .#charlie` 和 `nix build .#darwinConfigurations.charlie.system` 均通过。
- Axiom/Linux 侧 `programs.nix-ld.libraries` 仍 eval 出 56 项，Playwright npm/npx runtime intent 未丢失。

## Scope

In scope:

- 修改 `modules/dev/playwright.nix` 的 nix-ld 平台/option guard。
- 保留 Playwright package 和 Linux nix-ld library list。
- 记录验证、review、walkthrough、PR body 和 wiki evidence。

Out of scope:

- 不升级 flake inputs、nixpkgs 或 nix-darwin。
- 不重构 dev module 层。
- 不修改 autossh 配置或运行态 LaunchAgent。
- 不处理未来 switch activation 阶段可能出现的独立问题。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| Darwin 不再触发 `programs.nix-ld` unknown option | `docs/test-report.md` | PASS |
| `nix build .#darwinConfigurations.charlie.system` 已通过 | `docs/test-report.md` | PASS |
| Linux/Axiom nix-ld library list 仍保留 | `docs/test-report.md` | PASS |
| 变更范围局部且 review 通过 | `docs/review-change.md` | PASS |

## What Changed / What Was Decided

`modules/dev/playwright.nix` 新增 `hasNixLd`，通过 `options` 判断当前 module graph 是否提供 `programs.nix-ld`。nix-ld library attrset 改用 `optionalAttrs hasNixLd`，所以 nix-darwin 不会生成未知 option，而 NixOS 中该 option 存在时仍会生成相同 library list。

## Verification / Review Status

- `nix-instantiate --parse modules/dev/playwright.nix` 通过。
- `darwin-rebuild build --flake .#charlie` 通过。
- `nix build .#darwinConfigurations.charlie.system` 通过。
- `nix eval .#nixosConfigurations.axiom.config.programs.nix-ld.libraries --apply builtins.length` 返回 `56`。
- `git diff --check` 通过。
- `docs/review-change.md` 结论为 PASS。

## Risks and Limits

- 本 PR 解决 eval/build blocker，不直接执行 `sudo darwin-rebuild switch`。
- 如果合并后 switch 暴露 activation-time 问题，应作为独立 follow-up 处理，除非证据指回本 guard。

## Reviewer Checklist

- [ ] 确认 `optionalAttrs hasNixLd` 是正确的跨 module-system guard。
- [ ] 确认 Darwin build 和 explicit nix build 证据充分。
- [ ] 确认 Linux/Axiom nix-ld runtime intent 未被移除。

## Next Stage

PR-backed lifecycle 继续进入 `legion-wiki` 写回，然后提交、推送、创建 PR 并尝试 squash merge。HTML artifact 选择 artifact/local preview，不发布 Pages。
