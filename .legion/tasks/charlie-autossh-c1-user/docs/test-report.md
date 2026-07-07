# Test Report: Charlie Autossh C1 User

## Summary

PASS. `c1@8.159.128.125` 可以 batch 登录，并且使用同一账号时 `-R 127.0.0.1:2222:127.0.0.1:22` reverse forward 可以建立。配置文件语法和 targeted grep 也符合预期。

## Commands

### SSH 登录

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 true
```

Result: exit code 0，无 stderr。证明 `c1` 账号可由当前本机密钥非交互认证。

### Reverse forward

```sh
mkdir -p .ctl
rm -f .ctl/autossh-c1.sock
ssh -M -S "$PWD/.ctl/autossh-c1.sock" -fN \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -R 127.0.0.1:2222:127.0.0.1:22 \
  c1@8.159.128.125
ssh -S "$PWD/.ctl/autossh-c1.sock" -O check c1@8.159.128.125
ssh c1@8.159.128.125 "ssh-keyscan -T 5 -p 2222 127.0.0.1 2>/dev/null | sed -n '1,3p'"
ssh -S "$PWD/.ctl/autossh-c1.sock" -O exit c1@8.159.128.125
rm -f .ctl/autossh-c1.sock
rmdir .ctl
```

Key output:

```text
Master running (pid=20935)
# 127.0.0.1:2222 SSH-2.0-OpenSSH_10.2
[127.0.0.1]:2222 ssh-rsa <redacted>
# 127.0.0.1:2222 SSH-2.0-OpenSSH_10.2
Exit request sent.
```

Result: exit code 0。`ExitOnForwardFailure=yes` 让远端 bind 失败时命令直接失败；`ssh-keyscan` 从远端访问 `127.0.0.1:2222` 能看到 SSH endpoint，证明 reverse forward 不只是登录成功，而是远端 loopback 端口实际可达。

### Targeted grep

```sh
rg -n 'root@8\.159\.128\.125|c1@8\.159\.128\.125|127\.0\.0\.1:2222' hosts/charlie/default.nix
```

Output:

```text
92:          "127.0.0.1:2222:127.0.0.1:22"
93:          "c1@8.159.128.125"
```

Result: exit code 0。目标端口保持不变，tracked 配置中不再出现 `root@8.159.128.125`。

### Nix parse

```sh
nix-instantiate --parse hosts/charlie/default.nix >/dev/null
```

Result: exit code 0。

### Diff whitespace

```sh
git diff --check
```

Result: exit code 0。

## Skipped

- 未运行完整 `darwin-rebuild`。本次改动只有一个 launchd `ProgramArguments` 字符串，live SSH/forward 验证和 Nix parse 已直接覆盖风险点；完整部署仍应在 PR 合并后按常规 dotfiles 流程执行。

## Runtime Note

当前机器此前还存在未被仓库跟踪的 `~/Library/LaunchAgents/com.charlie.autossh.plist`，它仍指向 `root@8.159.128.125`。本 PR 不修改该 home-local 文件；部署 tracked 配置后应停用或删除旧 agent，避免重复 autossh 实例和旧错误日志继续刷屏。
