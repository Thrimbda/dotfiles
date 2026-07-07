# Charlie Autossh C1 User Log

## 2026-07-07

- 用户要求把 autossh 远端用户改为 `c1`，验证通过后按 Legion workflow 修改配置、提交并合并 PR。
- 入口判断：该仓库由 Legion 管理，任务会修改仓库文件，进入 `legion-workflow` 与 `git-worktree-pr` envelope。
- 选择 task id：`charlie-autossh-c1-user`。
- 风险判断：低风险局部配置修复，走 design-lite，不进入正式 RFC。
- 范围决策：只修改 tracked `hosts/charlie/default.nix`；本机未跟踪旧 plist `~/Library/LaunchAgents/com.charlie.autossh.plist` 作为运行时清理项记录，不纳入本 PR 修改。
- 实现：`hosts/charlie/default.nix` 中 autossh remote 已从 `root@8.159.128.125` 改为 `c1@8.159.128.125`。
- 验证：`c1@8.159.128.125` batch SSH 登录通过；临时 ControlMaster reverse forward 到远端 `127.0.0.1:2222` 建立成功，远端 `ssh-keyscan` 可见该 endpoint；`nix-instantiate --parse` 与 `git diff --check` 通过。
- Review：`docs/review-change.md` 判定 PASS。安全视角已覆盖 SSH identity/authentication；remote bind 仍为 loopback，端口与本地目标不变，没有扩大暴露面。
- Walkthrough：生成 `docs/report-walkthrough.html`、`docs/report-walkthrough.md` 与 `docs/pr-body.md`。`pr-html-render` 选择 artifact/local preview，因为报告含 SSH 运维细节、公网 IP 与 home-local plist 路径，不发布到 public Pages。
- Wiki：新增 `wiki/tasks/charlie-autossh-c1-user.md`，更新 reverse SSH current decisions 中 `charlie` 的 remote user 为 `c1@8.159.128.125`，并记录部署后清理 unmanaged stale LaunchAgent 的维护项。
