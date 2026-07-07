# Charlie Autossh C1 User

## Goal

把 `charlie` 上 declarative autossh reverse SSH 配置的远端登录用户从 `root` 改成 `c1`，让隧道使用当前可认证的远端账号连接 `8.159.128.125`。

## Problem

本机 `launchd` 中的 autossh 进程处于 running，但 stderr 持续报 `root@8.159.128.125: Permission denied (publickey)`。当前仓库里 `hosts/charlie/default.nix` 仍声明 `root@8.159.128.125`，这与本机可用 SSH 配置中 `azar` 的 `c1@8.159.128.125` 访问模型不一致。

## Acceptance

- `hosts/charlie/default.nix` 中 declarative autossh reverse SSH 目标改为 `c1@8.159.128.125`。
- 本地验证 `c1@8.159.128.125` 的 batch SSH 登录可用。
- 本地验证使用 `c1@8.159.128.125` 时 `-R 127.0.0.1:2222:127.0.0.1:22` reverse forward 可以建立。
- PR 说明记录当前本机仍存在未纳入仓库管理的旧 `~/Library/LaunchAgents/com.charlie.autossh.plist`，需要后续运行时清理或停用，避免重复 agent。

## Scope

- 修改 `hosts/charlie/default.nix` 中 autossh `ProgramArguments` 的远端 user。
- 新增本任务的 Legion 证据文档、验证报告、review 结论、walkthrough 和 PR body。
- 如验证显示必要，可在任务文档中记录运行时清理建议。

## Non-Goals

- 不在本 PR 中删除或编辑用户 home 下未被仓库跟踪的 `~/Library/LaunchAgents/com.charlie.autossh.plist`。
- 不改变 reverse SSH 远端端口 `2222`、远端 bind host `127.0.0.1`、本地目标 `127.0.0.1:22`。
- 不修改 Axiom、Azar 或 Linux `modules.services.reverse-ssh` 的行为。
- 不调整 SSH key、远端 `authorized_keys` 或远端 sshd 配置。

## Assumptions

- `c1@8.159.128.125` 是当前预期的远端账号，并可用 `/Users/c1/.ssh/id_ed25519` 认证。
- 远端 `c1` 用户有权限创建 loopback-only reverse forward `127.0.0.1:2222`。
- `charlie` 的 tracked declarative 配置由 `hosts/charlie/default.nix` 管理，运行时生效仍需要后续部署或 darwin rebuild。

## Constraints

- 通过 `git-worktree-pr` 在隔离 worktree 中交付，不直接修改主工作区。
- 变更保持最小化，避免混入旧 plist 清理、密钥管理或端口迁移。
- PR 合并前必须有可审阅验证证据。

## Risks

- 本机仍有旧 `com.charlie.autossh` LaunchAgent 指向 `root@8.159.128.125`，即使 tracked 配置修好，部署前/清理前它仍会继续失败。
- 若远端端口 `2222` 被旧连接或其他服务占用，reverse forward 验证会失败，需要运行时清理而不是扩大本 PR 范围。
- 如果远端账号权限变化，`c1` 认证或 remote forward 能力可能在 PR 合并后再次失效。

## Design Summary

- 采用最小配置修复：只把 `hosts/charlie/default.nix` 中 autossh 目标从 `root@8.159.128.125` 替换为 `c1@8.159.128.125`。
- 保留现有 autossh 参数和端口拓扑，降低行为漂移。
- 通过 live SSH batch 登录和临时 ControlMaster reverse forward 验证证明新账号可用。

## Phases

1. 建立 task contract 与 design-lite。
2. 修改 tracked charlie autossh 配置。
3. 验证 SSH 登录、reverse forward 建立和 targeted grep。
4. 完成 verify/review/walkthrough/wiki 证据。
5. 提交、推送、创建 PR、尝试 squash auto-merge/merge，并完成 cleanup 与主工作区 refresh。
