# Test Report: Darwin Playwright Nix-LD Guard

## Summary

PASS. `charlie` 的 Darwin system build 已通过，不再触发 `programs.nix-ld` unknown option。显式 `nix build .#darwinConfigurations.charlie.system` 也通过。Linux/Axiom 侧 Playwright nix-ld runtime intent 仍保留，`programs.nix-ld.libraries` eval 出 56 项。

## Commands

### Nix parse

```sh
nix-instantiate --parse modules/dev/playwright.nix >/dev/null
```

Result: exit code 0。

### Targeted guard grep

```sh
rg -n 'hasNixLd|optionalAttrs hasNixLd|programs\.nix-ld\.libraries|mkIf \(!isDarwin\)' modules/dev/playwright.nix
```

Output:

```text
10:  hasNixLd = builtins.hasAttr "programs" options && builtins.hasAttr "nix-ld" options.programs;
30:    (optionalAttrs hasNixLd {
33:      programs.nix-ld.libraries = with pkgs; [
```

Result: exit code 0。`programs.nix-ld` 仍存在，但现在只在 option 存在时通过 `optionalAttrs` 生成；旧的 `mkIf (!isDarwin)` shape 不再存在。

### Darwin build

```sh
darwin-rebuild build --flake .#charlie
```

Result: exit code 0。该命令成功构建 `charlie` Darwin system，产物为：

```text
/nix/store/b3mxyg4fqk89vqzdr1mksnsd9xydgn3q-darwin-system-25.11.ebec37a
```

该验证证明 nix-darwin 不再因 `programs.nix-ld` unknown option 在 eval 阶段失败。

### Explicit flake nix build

```sh
nix build .#darwinConfigurations.charlie.system
```

Result: exit code 0。

### Darwin toplevel eval

```sh
nix eval .#darwinConfigurations.charlie.config.system.build.toplevel.outPath
```

Output:

```text
"/nix/store/b3mxyg4fqk89vqzdr1mksnsd9xydgn3q-darwin-system-25.11.ebec37a"
```

Result: exit code 0。

### Linux/Axiom nix-ld library count

```sh
nix eval .#nixosConfigurations.axiom.config.programs.nix-ld.libraries --apply builtins.length
```

Output:

```text
56
```

Result: exit code 0。证明 Linux/Axiom 侧 Playwright nix-ld libraries 仍由模块提供。

### Generated charlie autossh LaunchAgent

```sh
plutil -p result/user/Library/LaunchAgents/org.nixos.autossh-reverse-ssh.plist
```

Key output:

```text
"127.0.0.1:2222:127.0.0.1:22"
"c1@8.159.128.125"
```

Result: exit code 0。构建产物中 `charlie` autossh remote 保持为已合并的 `c1@8.159.128.125`。

### Diff whitespace

```sh
git diff --check
```

Result: exit code 0。

## Skipped

- 未在 verification 阶段执行 `sudo darwin-rebuild switch --flake .#charlie`，因为本 task 先通过 PR 修复 repo 配置。PR 合并并刷新主工作区后再执行 switch。
