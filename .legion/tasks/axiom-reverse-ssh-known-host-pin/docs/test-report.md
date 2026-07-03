# Test Report

## 结果

通过。

## 已执行

- `nix eval --impure --json --expr '...'`
  - 目的：确认 Axiom 不再声明 hardcoded autossh remote host key pin。
  - 结果：`hasAutosshPin=false`，`programs.ssh.knownHosts={}`。
  - 备注：NixOS 仍生成空的 `/etc/ssh/ssh_known_hosts` etc entry，内容为换行；不再包含 `8.159.128.125` key。
- `git diff --check`
  - 结果：通过。
- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'`
  - 结果：通过。

## 未执行

- 未修改用户 `~/.config/ssh/known_hosts` 或 `~/.ssh/known_hosts`。
- 未做 live SSH 登录 smoke；远端 host key 信任由用户在重装后自行确认。
