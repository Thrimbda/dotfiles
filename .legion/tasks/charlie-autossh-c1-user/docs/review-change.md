# Review Change: Charlie Autossh C1 User

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

生产配置改动只有一处：`hosts/charlie/default.nix` 中 autossh remote 从 `root@8.159.128.125` 改为 `c1@8.159.128.125`。这符合 `plan.md` scope。

没有修改以下 out-of-scope 项：

- reverse SSH remote port `2222`
- remote bind host `127.0.0.1`
- local target `127.0.0.1:22`
- Axiom/Azar/Linux reverse SSH 配置
- SSH key 或远端 `authorized_keys`

## Correctness Review

验证证据覆盖了本次变更的核心风险：

- `c1@8.159.128.125` batch SSH 登录通过。
- 使用 `c1` 建立同形 `-R 127.0.0.1:2222:127.0.0.1:22` 成功。
- 远端 `ssh-keyscan -p 2222 127.0.0.1` 可以看到 SSH endpoint。
- `nix-instantiate --parse hosts/charlie/default.nix` 通过。
- `git diff --check` 通过。

## Security Lens

Applied, because the change touches SSH identity/authentication.

The change does not expand exposure:

- remote forward remains bound to remote loopback `127.0.0.1`
- remote port remains `2222`
- local target remains local SSH daemon on `127.0.0.1:22`
- no new key, token, secret, or public listener is introduced

The identity change from `root` to `c1` reduces reliance on root SSH authentication for this tunnel and matches the verified current access path.

## Non-blocking Runtime Note

当前机器仍存在未被仓库跟踪的 `~/Library/LaunchAgents/com.charlie.autossh.plist`，它仍指向 `root@8.159.128.125`。这不是本 PR 的 tracked diff，但部署后应停用或删除旧 agent，避免重复进程和旧 publickey 错误继续出现。
