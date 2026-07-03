# Test Report

## 结果

通过。

## 已执行

- `nix eval --impure --json --expr '...'` focused config check：确认 Axiom Docker package 为 `docker-29.2.0`，Discord package 可求值，Foot local config 仍使用 `FiraCode Nerd Font Mono:size=9.500000`，terminal font package 已进入 `fonts.packages`。
- `nix eval --impure --raw --expr '...' | zsh -n`：确认合并后的 user activation script 语法通过。
- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'`：Axiom toplevel build 通过。
- `git diff --check`：无 whitespace 问题。
- 使用用户当前主工作区 lock 的 focused expression 验证条件式 Vesktop override：`vesktop-1.6.5` 下存在 `pnpm_10_29_2` 参数，并替换为 `pnpm-10.34.4`。

## Live 观察

- `hey hook startup` 在当前已 switch 系统中失败：`spork/json.so: config mismatch - host 1.41.2 vs. module 1.39.1`。
- 绕过 `hey` 直接运行 live hook 中的 `caelestia-session start` 后，`caelestia-session run` 进程出现，说明 Caelestia binary/session runner 本身可启动。
- 当前 live `fc-match 'FiraCode Nerd Font Mono'` 回退到中文字体；修复通过把 terminal font package 放进系统 `fonts.packages`，让 fontconfig cache 包含该字体。

## 剩余风险

- 本轮没有做完整 GUI 重启 smoke；需要用户下一次 `switch` 后确认 Caelestia 自启动和 Foot 字体恢复。
