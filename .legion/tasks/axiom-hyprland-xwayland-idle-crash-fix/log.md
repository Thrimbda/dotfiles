# Axiom Hyprland XWayland Idle Crash Fix - 日志

## 会话进展 (2026-08-19)

### ✅ 已完成

- 确认故障发生在 DPMS-only idle，而非系统 suspend；保留 15 分钟锁屏和 30 分钟 DPMS 的用户策略。
- 审核 Hyprland 0.56.1/0.56.2 的相关 floating-layout 源码，拒绝没有针对性修复的版本升级。
- 在 Axiom 禁用 Hypridle user unit，让 Caelestia 成为唯一自动 idle owner，并保留 RustDesk、XWayland 和 Caelestia WlSessionLock。
- 重写 monitor hotplug watcher，使其通过 `hyprctl instances -j` 发现当前 socket；socket 缺失或任意事件流结束后均退避，而非持续连接旧 signature。
- 完成 focused Nix eval、生成脚本 `bash -n`、实时 instance 查询和 `git diff --check`；RFC 与 change review 均为 PASS。
- Final rendered assertion confirms the watcher waits after every event-stream completion, not only after a non-zero socket failure.
- Final independent change review passed with no correctness, scope, maintainability, or security finding.

### 🟡 进行中

- 写回 Legion wiki，并通过隔离 worktree 提交、rebase、push 和 PR 交付。

### ⚠️ 阻塞/待定

- 真实 30 分钟 DPMS/wake smoke 不能在当前桌面会话中自动触发；部署后必须在 Axiom 图形会话中完成并收集 journal/coredump 证据。
- 上游 Hyprland XWayland/DRM crash 仍是残余风险；本任务不将本地 idle-owner 收敛表述为根因修复。
- Main worktree has unrelated dirty and untracked state, including a host file touched by this task. Do not reset or force-refresh it during eventual PR cleanup.

---

## 关键文件

- `hosts/axiom/default.nix`: Axiom-specific `hypridle.enable = false`。
- `modules/desktop/hyprland.nix`: Hypridle service gate and dynamic hotplug socket watcher。
- `docs/rfc.md`, `docs/test-report.md`, `docs/review-rfc.md`, `docs/review-change.md`: design and verification evidence。

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Caelestia is Axiom's sole automatic idle owner | It already owns WlSessionLock and uses the current DPMS dispatcher; two 900/1800-second owners create unnecessary races | Make legacy Hypridle DPMS syntax work | 2026-08-19 |
| Do not upgrade Hyprland to 0.56.2 for this incident | The implicated source is unchanged between 0.56.1 and 0.56.2 | Version-only upgrade | 2026-08-19 |
| Re-discover the hotplug event socket for every reconnect | A static `HYPRLAND_INSTANCE_SIGNATURE` survives a compositor failure and points to a dead socket | Retry the stale socket indefinitely | 2026-08-19 |

---

## 快速交接

**下次继续从这里开始：**

1. Finish wiki writeback, run final scoped checks, then commit/rebase/push/create the PR from the dedicated worktree.
2. After deployment, stop any old `hypridle.service`, restart the graphical session if needed, and run the documented long-idle wake smoke.

**注意事项：**

- subagent 不直接改写 .legion 三文件。

---

*最后更新: 2026-08-19 04:22 by OpenCode*
