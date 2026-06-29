# Test Report

## Summary

- Result: PASS for targeted Linux/shell/terminal validation.
- Known residual: Darwin eval still fails on the pre-existing `modules/dev/playwright.nix` reference to `programs.nix-ld`, which does not exist on nix-darwin. This is outside the task scope and was already identified before this PR handoff.

## Why These Checks

- Residual search directly verifies the removed theme terminal contract is no longer referenced by repository modules/scripts/hosts.
- Axiom terminal font and Foot local config evals verify the new `modules.desktop.term.font` owner is exported and consumed by Foot.
- Axiom/Atlas/Acorn system derivation evals cover the main desktop host, an Autumnal/Rofi desktop sample, and a server sample with zsh/tmux enabled.
- Zsh syntax checks cover the moved prompt and runtime helper script edits.
- `git diff --check` catches whitespace errors before commit.

## Commands

### Residual Reference Search

```sh
rg 'modules/themes/autumnal/config/(zsh|tmux)|hey info theme fonts terminal|fonts\.terminal' modules config hosts
```

Result: PASS, no output.

### Theme Shell Asset Orphan Check

```sh
git diff --name-status -- 'modules/themes/*/config/zsh/*' 'modules/themes/*/config/tmux*'
```

Result: PASS. The unstaged diff at verification time deleted all tracked shell/tmux config assets that remained under `modules/themes`.

```text
D	modules/themes/autumnal-cli/config/tmux.conf
D	modules/themes/autumnal-cli/config/zsh/prompt.zsh
D	modules/themes/autumnal/config/tmux.conf
D	modules/themes/autumnal/config/zsh/prompt.zsh
```

```text
Glob modules/themes/*/config/{zsh,tmux*}/**: no files found in the worktree.
```

After staging, Git represented one duplicate asset pair as the move into `config/` and the other duplicate pair as deletes:

```sh
git diff --cached --name-status -- 'modules/themes/*/config/zsh/*' 'modules/themes/*/config/tmux*' 'config/zsh/prompt.zsh' 'config/tmux/theme.conf'
```

```text
R100	modules/themes/autumnal-cli/config/tmux.conf	config/tmux/theme.conf
R100	modules/themes/autumnal-cli/config/zsh/prompt.zsh	config/zsh/prompt.zsh
D	modules/themes/autumnal/config/tmux.conf
D	modules/themes/autumnal/config/zsh/prompt.zsh
```

### Axiom Terminal Font Info

```sh
nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.hey.info.term.font
```

Result: PASS.

```json
{"name":"FiraCode Nerd Font Mono","size":9.5}
```

### Axiom Foot Local Config

```sh
nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home.configFile."foot/foot.local.ini".text'
```

Result: PASS.

```ini
[main]
font=FiraCode Nerd Font Mono:size=9.500000
```

### Zsh Syntax

```sh
zsh -n config/zsh/.zshrc && zsh -n config/zsh/prompt.zsh && zsh -n config/hypr/bin/get-font.zsh && zsh -n config/hypr/bin/open-term.zsh
```

Result: PASS, no output.

### Diff Whitespace

```sh
git diff --check
```

Result: PASS, no output.

After staging all scoped files, cached whitespace validation also passed:

```sh
git diff --check --cached
```

Result: PASS, no output.

### Representative NixOS Evals

```sh
nix eval --option eval-cache false --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath
nix eval --option eval-cache false --raw .#nixosConfigurations.atlas.config.system.build.toplevel.drvPath
nix eval --option eval-cache false --raw .#nixosConfigurations.acorn.config.system.build.toplevel.drvPath
```

Result: PASS.

```text
/nix/store/qabb04kd8jvdbkq1wqlb1k2m1b7bry6d-nixos-system-axiom-25.11.20260203.e576e3c.drv
/nix/store/ipla0j1xlicxw47vvgxvfc7xqycw50sb-nixos-system-atlas-25.11.20260203.e576e3c.drv
/nix/store/cwk8b3jd6l0161251bzspmhbldq9nmxy-nixos-system-acorn-25.11.20260203.e576e3c.drv
```

After removing orphaned `autumnal-cli` shell/tmux assets, Axiom and Acorn evals were rerun and still passed:

```text
/nix/store/nc460g8nlnzjybj68ljkil8myfjxkp9p-nixos-system-axiom-25.11.20260203.e576e3c.drv
/nix/store/yhv7gd2cyyq9w8z24r2w506mn575j41i-nixos-system-acorn-25.11.20260203.e576e3c.drv
```

### Shell/Tmux Theme Injection Evals

```sh
nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.modules.shell.zsh.rcFiles
nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.modules.shell.tmux.rcFiles
nix eval --option eval-cache false --json .#nixosConfigurations.acorn.config.modules.shell.zsh.rcFiles
nix eval --option eval-cache false --json .#nixosConfigurations.acorn.config.modules.shell.tmux.rcFiles
```

Result: PASS. Axiom and Acorn zsh `rcFiles` contain only non-theme aliases, and tmux `rcFiles` is empty, confirming prompt/theme ownership moved out of `modules/themes` injection.

### Darwin Eval

```sh
nix eval --option eval-cache false --raw .#darwinConfigurations.charles.config.system.build.toplevel.drvPath
```

Result: KNOWN FAIL, outside this task scope.

```text
error: The option `programs.nix-ld' does not exist.
Definition values:
- In `.../modules/dev/playwright.nix': ...
```
