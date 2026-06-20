# Implementation Review

> 本 PR body 只是 PR 创建输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 为 `axiom` 增加独立命令 `axiom-mode`，用于在 SSH-friendly CLI 模式和 Hyprland 桌面模式之间切换。
- CLI 模式通过 `axiom-cli.target` 实现，保留 `multi-user.target` 下的远程访问服务。
- 实现不依赖 `hey`、`hey` hooks 或 `hey` runtime commands。

## 范围

**In scope**

- `hosts/axiom/default.nix`: 新增 `axiom-mode` 和 `axiom-cli.target`。
- `hosts/axiom/README.org`: 新增模式切换说明。
- `.legion/tasks/axiom-cli-mode/**`: 新增 task contract、验证、review 和 walkthrough 证据。

**Out of scope**

- NVIDIA 深度省电调优。
- CPU governor、suspend、风扇、DDC 或显示器电源控制。
- 第二套 host 配置或 NixOS specialisation。
- 远程访问拓扑调整。

## 主要改动

- `axiom-mode cli` 持久设置默认 target 为 `axiom-cli.target` 并立即 isolate。
- `axiom-mode desktop` 持久设置默认 target 为 `graphical.target` 并立即 isolate。
- `axiom-mode status` 显示默认 target 和关键 unit 状态，不需要 root。
- `axiom-cli.target` requires `multi-user.target`，wants `getty@tty1.service`，conflicts `graphical.target`，并允许 isolate。

## 验证与审查

- 验证: `.legion/tasks/axiom-cli-mode/docs/test-report.md`
- 变更审查: `.legion/tasks/axiom-cli-mode/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-cli-mode/docs/report-walkthrough.md`
- HTML walkthrough: `.legion/tasks/axiom-cli-mode/docs/report-walkthrough.html`

## 风险与限制

- `systemctl isolate` 会立即结束图形会话，切换前需要保存桌面工作。
- Runtime isolate 和实际功耗测量需要部署到 live `axiom` 后执行。
- 本 PR 不承诺 GPU runtime power management 或显示器电源控制调优。

## 评审重点

- [ ] 变更是否符合 task contract 与 scope？
- [ ] `axiom-mode` 是否真的独立于 `hey`？
- [ ] `axiom-cli.target` 是否正确保留 SSH/reverse SSH/cloudflared/opencode 路径？
- [ ] deferred live checks 是否合理？

## 证据链接

- plan: `.legion/tasks/axiom-cli-mode/plan.md`
- test-report: `.legion/tasks/axiom-cli-mode/docs/test-report.md`
- review-change: `.legion/tasks/axiom-cli-mode/docs/review-change.md`
- report-walkthrough: `.legion/tasks/axiom-cli-mode/docs/report-walkthrough.md`
- report-walkthrough-html: `.legion/tasks/axiom-cli-mode/docs/report-walkthrough.html`
