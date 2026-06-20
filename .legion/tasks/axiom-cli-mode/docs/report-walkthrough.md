# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务为 `axiom` 增加一个不依赖 `hey` 的本机命令 `axiom-mode`，用于在 SSH-only CLI 模式和 Hyprland 桌面模式之间切换。
- CLI 模式通过 `axiom-cli.target` 表达，保留 `multi-user.target` 下的 SSH、reverse SSH、cloudflared 和 opencode 服务。
- 变更审查结论为 PASS，验证覆盖 NixOS 目标关系、脚本生成与系统 dry-run。

## Scope

In scope:

- `hosts/axiom/default.nix` 增加 `axiom-mode` 和 `axiom-cli.target`。
- `hosts/axiom/README.org` 增加使用说明。
- `.legion/tasks/axiom-cli-mode/**` 记录 task contract、验证、review 和交付说明。

Out of scope:

- 不做 NVIDIA 深度省电调优。
- 不调整 CPU governor、suspend、风扇、DDC 或显示器电源控制。
- 不创建第二套 host 配置或 NixOS specialisation。
- 不改变远程访问拓扑。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| CLI mode 有明确 task contract | `.legion/tasks/axiom-cli-mode/plan.md` | PASS |
| `axiom-mode` 不依赖 `hey` 且进入系统包 | `.legion/tasks/axiom-cli-mode/docs/test-report.md` | PASS |
| `axiom-cli.target` 保留远程访问服务路径 | `.legion/tasks/axiom-cli-mode/docs/test-report.md` | PASS |
| 变更没有 scope 外服务拓扑调整 | `.legion/tasks/axiom-cli-mode/docs/review-change.md` | PASS |
| sudo/systemctl 权限路径已做安全视角检查 | `.legion/tasks/axiom-cli-mode/docs/review-change.md` | PASS |

## What Changed / What Was Decided

`axiom-mode cli` 会持久设置默认 target 为 `axiom-cli.target`，再立即 isolate。该 target requires `multi-user.target`，wants `getty@tty1.service`，并 conflicts `graphical.target`。

`axiom-mode desktop` 会持久设置默认 target 为 `graphical.target`，再立即 isolate，让 greetd/UWSM 重新进入 Hyprland 桌面路径。

`axiom-mode status` 不需要 root，展示默认 target 和关键 unit 状态，并使用 `list-units --all` 避免 inactive unit 被漏掉。

## Verification / Review Status

- 验证: PASS，见 `docs/test-report.md`。
- 变更审查: PASS，见 `docs/review-change.md`。
- 运行时 isolate 未在当前环境执行，因为当前环境不是 live `axiom` 主机。

## Risks and Limits

- `systemctl isolate` 会立即结束图形会话，使用者应在切换前保存桌面工作。
- 真实省电幅度取决于 RTX 5090 空闲功耗、显示器状态和 live host 电源管理状态。
- 本任务只提供模式切换，不承诺完成 GPU runtime power management 调优。

## Reviewer Checklist

- [ ] `axiom-mode` 是否足够独立，不依赖 `hey`？
- [ ] `axiom-cli.target` 是否正确保留 `multi-user.target` 下的远程访问路径？
- [ ] README 是否清楚说明 CLI 和 desktop 模式的持久切换语义？
- [ ] deferred runtime checks 是否合理留到 live `axiom` 部署后执行？

## Next Stage

PR-backed lifecycle 继续执行：先提交并创建 PR，然后处理 HTML render handoff、checks/review、auto-merge、cleanup 和主工作区 refresh。`pr-body.md` 仅作为 PR 创建输入，不代表 PR lifecycle 已完成。
