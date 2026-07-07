# Design-lite: Darwin Playwright Nix-LD Guard

## Decision

将 `modules/dev/playwright.nix` 中的 `programs.nix-ld.libraries` 定义限制为 Linux-only，使 nix-darwin 的 `charlie` 配置不再评估不存在的 `programs.nix-ld` option。

## Rationale

`programs.nix-ld` 是 Linux/NixOS runtime compatibility mechanism。Darwin 不使用 nix-ld，也没有对应 module option。最小修复是给该配置加平台 guard，而不是删除 Playwright support 或改动整个 dev module 结构。

## Verification Plan

- `darwin-rebuild build --flake .#charlie`
- `nix-instantiate --parse modules/dev/playwright.nix`
- targeted grep 确认 `programs.nix-ld` 仍存在但受 Linux guard 约束
- `git diff --check`

## Rollback

如 guard 误伤 Linux Playwright runtime，revert 本 PR 恢复原始 `programs.nix-ld.libraries` 定义，再用单独任务重新设计跨平台 Playwright runtime。
