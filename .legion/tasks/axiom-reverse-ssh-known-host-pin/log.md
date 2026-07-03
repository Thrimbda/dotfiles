# Axiom Reverse SSH Known Host Pin - 日志

- 用户反馈：远端 `8.159.128.125` 重装系统后 hardcoded `remoteHostKey` 失效，并通过 Nix-managed `/etc/ssh/ssh_known_hosts` 阻止登录。
- 决策：只移除 Axiom host-local pin，不改 reusable reverse-ssh module，也不关闭 SSH host key checking。
- 实现：删除 `hosts/axiom/default.nix` 中的 `autosshRemoteHostKey` 常量，以及 `modules.services.reverse-ssh.remoteHostKey` / `knownHostName` 传参。
- 验证：Axiom evaluated `programs.ssh.knownHosts` 为空，`autossh-remote-8.159.128.125` 不再存在；Axiom toplevel build 通过。
