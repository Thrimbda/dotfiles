# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本 PR 把 `charlie` 的 declarative autossh reverse SSH remote 从 `root@8.159.128.125` 改为 `c1@8.159.128.125`。
- 端口拓扑保持不变：远端 `127.0.0.1:2222` 转发到本机 `127.0.0.1:22`。
- live 验证已确认 `c1` 可 batch 登录，且同形 reverse forward 可以建立并从远端看到 SSH endpoint。
- Review PASS，安全视角已确认没有扩大监听暴露面。

## Scope

In scope:

- 修改 `hosts/charlie/default.nix` 中 autossh remote user。
- 保留现有 autossh 参数、remote bind、remote port 和 local target。
- 记录验证、review、walkthrough 和 PR body 证据。

Out of scope:

- 不修改未被仓库跟踪的 `~/Library/LaunchAgents/com.charlie.autossh.plist`。
- 不调整 SSH key、远端 `authorized_keys` 或远端 sshd。
- 不修改 Axiom、Azar 或 Linux reverse SSH 模块。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| tracked 配置已改为 `c1@8.159.128.125` | `hosts/charlie/default.nix`; targeted grep in `docs/test-report.md` | PASS |
| `c1` SSH 登录可用 | `docs/test-report.md` | PASS |
| 同形 reverse forward 可建立 | `docs/test-report.md` | PASS |
| Nix 语法和 diff 检查通过 | `docs/test-report.md` | PASS |
| scope 和安全视角通过 review | `docs/review-change.md` | PASS |

## What Changed / What Was Decided

只修改一处生产配置，把 autossh 的 remote 参数从 `root@8.159.128.125` 替换为 `c1@8.159.128.125`。选择最小替换是因为故障点是 root publickey 认证失败，而现有 `c1` 账号已经是当前远端入口。

## Verification / Review Status

- `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 true` 通过。
- 临时 ControlMaster 使用 `ExitOnForwardFailure=yes` 建立 `-R 127.0.0.1:2222:127.0.0.1:22` 通过。
- 远端 `ssh-keyscan -p 2222 127.0.0.1` 能看到 SSH endpoint。
- `nix-instantiate --parse hosts/charlie/default.nix` 通过。
- `git diff --check` 通过。
- `docs/review-change.md` 结论为 PASS。

## Risks and Limits

- 本机仍有 unmanaged `~/Library/LaunchAgents/com.charlie.autossh.plist` 指向 root，部署 tracked 配置后应停用或删除旧 agent。
- 本 PR 不执行 darwin rebuild。合并后仍需按常规 dotfiles 流程部署。
- 如果远端 `c1` 权限后续变化，隧道仍可能再次失败。

## Reviewer Checklist

- [ ] 确认 `hosts/charlie/default.nix` 的一行 user 替换符合预期。
- [ ] 确认证据足以覆盖 SSH 认证和 reverse forward 风险。
- [ ] 确认旧 unmanaged plist 作为运行时清理项记录即可，不应纳入本 PR。

## Next Stage

PR-backed lifecycle 继续进入 `legion-wiki` 写回，然后提交、推送、创建 PR、尝试 squash 合并。`pr-html-render` 选择 artifact/local preview：HTML 包含 SSH 运维细节、公网 IP 与 home-local plist 路径，不发布到 public Pages；reviewer 可直接打开 `.legion/tasks/charlie-autossh-c1-user/docs/report-walkthrough.html`。`pr-body.md` 只是 PR 创建输入，不代表 PR lifecycle 已完成。
