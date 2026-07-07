# Implementation Review

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 将 `charlie` 的 declarative autossh reverse SSH remote 从 `root@8.159.128.125` 改为 `c1@8.159.128.125`。
- 保留现有 reverse tunnel 拓扑：远端 `127.0.0.1:2222` 到本机 `127.0.0.1:22`。
- 已验证 `c1` batch SSH 登录和同形 reverse forward 均可用。

## 范围

**In scope**

- `hosts/charlie/default.nix` 中 autossh remote user。
- Legion task 文档、验证报告、review 结论和 walkthrough。

**Out of scope**

- 不修改未被仓库跟踪的 `~/Library/LaunchAgents/com.charlie.autossh.plist`。
- 不调整 SSH key、远端 `authorized_keys`、远端 sshd 或其他 host 的 tunnel 配置。

## 主要改动

- `hosts/charlie/default.nix`: `root@8.159.128.125` -> `c1@8.159.128.125`

## 验证与审查

- 验证: `.legion/tasks/charlie-autossh-c1-user/docs/test-report.md`
- 变更审查: `.legion/tasks/charlie-autossh-c1-user/docs/review-change.md`
- Design-lite: `.legion/tasks/charlie-autossh-c1-user/docs/rfc.md`

验证摘要：

- `ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 true` 通过。
- 使用 `c1` 建立 `-R 127.0.0.1:2222:127.0.0.1:22` 通过。
- 远端 `ssh-keyscan -p 2222 127.0.0.1` 可见 SSH endpoint。
- `nix-instantiate --parse hosts/charlie/default.nix` 通过。
- `git diff --check` 通过。
- `review-change` PASS，已覆盖 SSH identity/authentication 安全视角。

## 风险与限制

- 当前机器仍有 unmanaged `~/Library/LaunchAgents/com.charlie.autossh.plist` 指向 `root@8.159.128.125`。本 PR 不修改 home-local 文件，部署后应停用或删除旧 agent。
- 本 PR 不执行 darwin rebuild，合并后需按常规 dotfiles 流程部署。

## 评审重点

- [ ] 变更是否符合 task contract 与 scope？
- [ ] 验证证据是否足以支撑交付结论？
- [ ] 风险、限制与 non-goals 是否已经清楚暴露？

## 证据链接

- plan: `.legion/tasks/charlie-autossh-c1-user/plan.md`
- rfc: `.legion/tasks/charlie-autossh-c1-user/docs/rfc.md`
- test-report: `.legion/tasks/charlie-autossh-c1-user/docs/test-report.md`
- review-change: `.legion/tasks/charlie-autossh-c1-user/docs/review-change.md`
- report-walkthrough: `.legion/tasks/charlie-autossh-c1-user/docs/report-walkthrough.md`
