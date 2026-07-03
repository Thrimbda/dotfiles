# Axiom Reverse SSH Known Host Pin

## 目标

移除 Axiom 对远端 `8.159.128.125` SSH host key 的系统级硬编码 pin，避免远端重装系统后 `/etc/ssh/ssh_known_hosts` 中的 Nix-managed 旧 key 阻止登录。

## 问题

`hosts/axiom/default.nix` 把 `autosshRemoteHostKey` 传给 `modules.services.reverse-ssh.remoteHostKey`。该模块会生成 `programs.ssh.knownHosts`，最终写入 `/etc/ssh/ssh_known_hosts`。远端机器重装后 host key 改变，系统级 known-host pin 变成 stale，交互式 SSH 和 autossh 都会先被全局 host-key policy 卡住。

## 验收标准

- Axiom evaluated config 不再包含 `programs.ssh.knownHosts."autossh-remote-8.159.128.125"`。
- Axiom evaluated `/etc/ssh/ssh_known_hosts` 不再由该 host-local remote key pin 生成。
- `modules.services.reverse-ssh.remoteHostKey` 的模块能力保留，其他 host 仍可显式 opt in。
- Axiom toplevel build 通过。

## 范围

- `hosts/axiom/default.nix` host-local reverse-ssh key pin。
- 任务文档、验证记录和 wiki writeback。

## 非范围

- 不修改 reusable `modules/services/reverse-ssh.nix` 选项语义。
- 不自动改写用户 `~/.config/ssh/known_hosts` 或 `~/.ssh/known_hosts`。
- 不关闭 SSH host key checking。
- 不改变 autossh remote host、remote port 或 tunnel topology。

## 推荐方向

删除 Axiom host-local `autosshRemoteHostKey` 常量和 `remoteHostKey` / `knownHostName` 传参，让 remote host trust 回到用户本地 known_hosts 或临时人工确认流程；健康检查仍可验证 reverse endpoint 是否连回 Axiom，但不再由 Nix 写死远端服务器 host key。
