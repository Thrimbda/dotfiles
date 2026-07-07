# Design-lite: Charlie Autossh C1 User

## Decision

将 `hosts/charlie/default.nix` 中 `launchd.user.agents.autossh-reverse-ssh.serviceConfig.ProgramArguments` 的 remote 从 `root@8.159.128.125` 改为 `c1@8.159.128.125`。

## Rationale

运行态日志显示 `root@8.159.128.125` 持续 publickey 认证失败；当前 SSH 配置中的远端入口 `azar` 使用 `c1@8.159.128.125`。只替换 remote user 可以修复认证目标，同时保留现有 reverse tunnel 拓扑和 autossh 参数。

## Verification Plan

- `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 true`
- 使用临时 ControlMaster 运行 `ssh -M -S <repo-local-control-path> -fN -o ExitOnForwardFailure=yes -R 127.0.0.1:2222:127.0.0.1:22 c1@8.159.128.125`，确认 forward 建立后关闭 master。
- `rg -n 'root@8\\.159\\.128\\.125|c1@8\\.159\\.128\\.125|127\\.0\\.0\\.1:2222' hosts/charlie/default.nix`

## Rollback

如 `c1` 账号在远端不可用或不应承载该 tunnel，直接 revert 本 PR，将 remote 恢复为 `root@8.159.128.125`，并另行修复 root 的 `authorized_keys`。
