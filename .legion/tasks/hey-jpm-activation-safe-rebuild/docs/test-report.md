# Test Report

## 结果

通过。

## 已执行

- `nix eval --impure --raw --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; in c.system.userActivationScripts.script' | zsh -n`
  - 目的：确认合并后的 user activation shell 语法正确。
  - 结果：通过。
- `nix eval --impure --json --expr '...'`
  - 目的：确认 evaluated activation script 包含 staging rebuild、runtime probe、`project.janet` hash marker。
  - 结果：`hasStaging=true`、`hasRuntimeProbe=true`、`hasProjectHash=true`。
- `git diff --check`
  - 目的：检查 whitespace。
  - 结果：通过。
- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'`
  - 目的：确认 Axiom NixOS toplevel 仍可 build，且 activation script 能被系统闭包构建。
  - 结果：通过。

## 未执行

- 没有在当前 live system 直接重建 `~/.local/share/janet/jpm_tree`；该操作留给下一次 switch 或用户确认后的手动修复。
- 没有实现 `c1ctl hook`，这是明确的非范围。
