# Darwin Playwright Nix-LD Guard

## Goal

修复 `charlie` 的 `darwin-rebuild switch --flake .#charlie` eval 失败，让 Darwin 配置不再评估 Linux-only 的 `programs.nix-ld` option。

## Problem

`sudo darwin-rebuild switch --flake .#charlie` 在评估阶段失败：

```text
error: The option `programs.nix-ld' does not exist.
Definition values:
- In `.../modules/dev/playwright.nix'
```

这说明 Playwright 开发模块里有 NixOS-only 配置没有被平台条件隔离，导致 nix-darwin 模块系统看到不存在的 `programs.nix-ld` option。

## Acceptance

- `modules/dev/playwright.nix` 中 `programs.nix-ld` 只在 Linux/NixOS 上启用。
- `darwin-rebuild build --flake .#charlie` 可以越过当前 `programs.nix-ld` eval 错误。
- 验证不改变 Playwright 相关 Linux runtime intent：Linux 上仍可为 Playwright 注入 nix-ld libraries。
- PR 说明记录本次只修平台 guard，不处理其他 Darwin switch 阶段可能暴露的新问题。

## Scope

- 修改 `modules/dev/playwright.nix` 的平台条件或 module shape。
- 新增本任务 Legion 证据文档、验证报告、review、walkthrough 和 wiki writeback。
- 必要时使用 targeted eval/build 命令证明 Darwin 不再触发 `programs.nix-ld`。

## Non-Goals

- 不升级 Playwright、nixpkgs、nix-darwin 或 flake inputs。
- 不重构整个 dev module 层。
- 不改变 autossh 配置或运行态 LaunchAgent。
- 不承诺 `darwin-rebuild switch` 后续所有 activation 阶段问题都在本任务内解决。

## Assumptions

- `programs.nix-ld` 是 NixOS/Linux module option，nix-darwin 不提供该 option。
- Playwright 在 Darwin 上不需要 nix-ld library injection。
- 当前失败的直接 blocker 是 `modules/dev/playwright.nix` 中缺少平台 guard。

## Constraints

- 通过 `git-worktree-pr` 在隔离 worktree 中完成修改、验证、PR 和合并。
- 修复应保持最小化，避免扩散到 unrelated dev modules。
- 验证命令不应写入 repo 外持久化产物。

## Risks

- 修掉 `programs.nix-ld` 后，Darwin build/switch 可能暴露另一个独立问题；这应作为新的 blocker 记录，而不是扩大本任务。
- 如果条件 guard 写错，可能误关掉 Linux 上 Playwright 需要的 nix-ld libraries。
- 若完整 `darwin-rebuild switch` 需要 sudo，CI/agent 可能只能完成非 sudo build 验证。

## Design Summary

- 采用最小平台 guard：将 `programs.nix-ld.libraries` 包在 Linux-only 条件下。
- 保持 Playwright packages、browser tooling 和现有模块入口不变。
- 用 Darwin build 验证 nix-darwin 不再看到 `programs.nix-ld`，用 targeted grep/eval 检查 Linux-only intent 仍在。

## Phases

1. 创建 task contract 和 design-lite。
2. 修改 `modules/dev/playwright.nix` 平台 guard。
3. 验证 `darwin-rebuild build --flake .#charlie`、targeted grep/eval 与 diff check。
4. 完成 review、walkthrough 和 wiki writeback。
5. 提交、推送、开 PR、合并、清理 worktree，刷新主工作区。
6. 在 merged 主工作区重试 `sudo darwin-rebuild switch --flake .#charlie`。
