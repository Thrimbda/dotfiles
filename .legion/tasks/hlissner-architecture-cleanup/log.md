# Hlissner-aligned Dotfiles Architecture Cleanup - 日志

## 会话进展 (2026-05-12)
### 已完成
- 按用户要求进入 `legion-workflow`，因未指定可恢复 task id，进入 `brainstorm` 新建任务契约。
- 只读审视当前仓库根目录、`.legion` 状态、README、flake/lib/default/darwin/modules/hosts 关键入口。
- 克隆 `hlissner/dotfiles` 到 `/tmp/opencode/hlissner-dotfiles` 作为只读参考，确认当前仓库仍保留其轻量自制 flake/module 架构骨架。
- 向用户确认重构边界；用户选择“允许轻微行为调整”。
- 创建本任务的 `plan.md`、`tasks.md` 和 `log.md`。
- 完成 research 汇总：当前仓库保留 hlissner 骨架，但安全清理点集中在平台/env、路径硬编码、Hyprland/Caelestia 常量和注释/边界噪音。
- 产出 `docs/rfc.md` 和 `docs/implementation-plan.md`；推荐 Option B（边界保持的 helper/path cleanup），明确不抽象 opencode/autossh/cloudflared 为新公共模块。
- 完成 RFC review，结论 PASS；吸收建议，要求任何轻微行为调整在 merge 前获得 reviewer/user 接受。

### 进行中
- 准备进入 `git-worktree-pr` envelope，在隔离 worktree 中实现。

### 阻塞/待定
- 无当前阻塞。后续实现必须在 git worktree/PR envelope 中进行，且 PR 不自动合并。

---

## 关键决策
| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 新建 `hlissner-architecture-cleanup` task，而非隐式恢复历史 Wayland task | 用户未指定可恢复 task id；Legion 入口门要求无明确恢复目标时走 brainstorm | 按最近任务恢复，已排除 | 2026-05-12 |
| 保留 hlissner 风格轻量框架作为方向 | 当前仓库已经基于该骨架扩展，替换框架会增加功能漂移风险 | 迁移 flake-parts/devos，超出本次 scope | 2026-05-12 |
| 允许极小行为调整但必须显式记录 | 用户选择“允许轻微行为调整”；仍需把不影响功能作为默认约束 | 绝对零行为变化或放开功能修复 | 2026-05-12 |

---

## 快速交接
**下次继续从这里开始：**
1. 补写 `docs/research.md`，引用当前仓库和 hlissner 参考的关键证据。
2. 回到 `legion-workflow`，按中高风险进入 `spec-rfc -> review-rfc`。
3. RFC PASS 后加载 `git-worktree-pr`，在隔离 worktree 中实施。

**注意事项：**
- 不读取 `token.env` 或 secret 明文。
- 不修改 flake lock 或自动 merge PR。
- 新增文件在 Git-backed flake 验证前需要确保被 Git 看到。

---
*Updated: 2026-05-12 00:00*
