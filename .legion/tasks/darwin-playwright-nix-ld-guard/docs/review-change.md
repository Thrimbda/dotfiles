# Review Change: Darwin Playwright Nix-LD Guard

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

生产代码改动仅限 `modules/dev/playwright.nix`：

- 新增 `hasNixLd`，通过 `options` 判断当前 module graph 是否提供 `programs.nix-ld`。
- 将 nix-ld libraries attrset 从 `mkIf (!isDarwin)` 改为 `optionalAttrs hasNixLd`。

这符合 task contract。没有修改 flake inputs、Playwright package set、autossh 配置或其他 dev modules。

## Correctness Review

原问题是 nix-darwin 看到不存在的 `programs.nix-ld` option。`optionalAttrs hasNixLd` 在 option 不存在时完全不生成该 attrset，比 `mkIf` 更适合跨 module-system option 存在性差异。

验证证据足够：

- `darwin-rebuild build --flake .#charlie` 通过。
- `nix build .#darwinConfigurations.charlie.system` 通过。
- `nix eval .#darwinConfigurations.charlie.config.system.build.toplevel.outPath` 返回构建好的 Darwin system path。
- `nix eval .#nixosConfigurations.axiom.config.programs.nix-ld.libraries --apply builtins.length` 返回 `56`，说明 Linux/Axiom Playwright nix-ld library list 仍保留。
- `nix-instantiate --parse modules/dev/playwright.nix` 和 `git diff --check` 通过。

## Security Lens

Not applied. This change only affects platform-conditional module option generation for development runtime libraries. It does not touch authentication, authorization, secrets, listeners, protocol boundaries, or user-controlled privileged paths.

## Non-blocking Notes

- `darwin-rebuild switch` still needs to be run after PR merge from the refreshed main workspace.
- If switch reveals an activation-time issue after this eval/build fix, treat that as a separate follow-up unless it points back to this guard.
