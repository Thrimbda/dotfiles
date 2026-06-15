# 日志：Axiom 4K 240Hz HDR 屏幕设置

## 2026-06-15

- 根据用户请求创建任务：为 Axiom 配置 4K 240Hz 屏幕，并在可行时启用 HDR。
- 读取当前 Axiom Hyprland 配置：monitor 为 `3840x2160@60`，位置 `0x0`，缩放 `1.5`。
- 读取当前共享 Hyprland 模块：monitor 选项只支持 `output`、`mode`、`position`、`scale`、`disable` 和 `primary`。
- 通过 Context7 查询当前 Hyprland 文档：HDR 需要 10-bit 输出和 `cm = hdr` 等色彩管理字段，`sdrbrightness`/`sdrsaturation` 为可选调节项。
- 记录现有 Axiom 约束：`render.cm_enabled = false` 用于规避 Hyprland 0.53.x 色彩管理在 DPMS/恢复时崩溃，所以除非明确改变并实机验证该保护，否则不能把 HDR 宣称为完整启用。
- 用户要求任务契约全部使用中文，已将 `plan.md`、`tasks.md` 和 `log.md` 改为中文。
- 进入 `git-worktree-pr` 外壳：base ref 为 `origin/master`，分支为 `legion/axiom-4k240-hdr-display`，worktree 为 `.worktrees/axiom-4k240-hdr-display/`。
- 用户补充优先级：HDR 没有 240Hz 高，目前实际看到的是 60Hz；本任务按“先确保 Axiom 请求 4K 240Hz”为主线推进，HDR 只做保守低优先级处理。
- RFC 审查结论为 PASS：240Hz 主线清晰，HDR 保持低优先级且不撤销现有色彩管理稳定性保护。
- 已实现配置改动：Axiom monitor mode 从 `3840x2160@60` 改为 `3840x2160@240`；共享 Hyprland monitor 模块新增可选 `bitdepth`、`cm`、`sdrbrightness`、`sdrsaturation` 字段，并仅在这些高级字段被设置时生成 `monitorv2`。
- Axiom 本次未设置 HDR 字段，也未移除 `cm_enabled = false`；配置注释明确 HDR 低于 240Hz，且需要后续实机重新测试色彩管理和 DPMS/恢复稳定性。
- 验证通过：`nix eval` 证明 Axiom 生成的 `hypr/monitors.conf` 为 `monitor = ,3840x2160@240,0x0,1.500000`；`git diff --check` 通过；`azar` 的 monitor 输出仍保持旧 `monitor = ...` 格式。
- Review 前修正 RFC 描述：高级字段不会追加到旧 `monitor = ...` 行，而是触发生成 `monitorv2` 块；这与实现保持一致。
- 补充验证通过：用 `extendModules` 临时设置 `output = "DP-1"`、`bitdepth = 10`、`cm = "hdr"`、`sdrbrightness = 1.2`、`sdrsaturation = 0.98`，确认新增字段可以生成 `monitorv2` 块。
- 变更评审结论为 PASS：无阻塞问题，未命中安全触发条件；残余风险是 240Hz/HDR 运行态仍需 Axiom 实机会话确认。
- 已生成 implementation 模式 walkthrough 和 PR body，供 reviewer 快速查看变更、验证与残余风险。
- 已完成 Legion wiki 收口：新增任务摘要，并更新 Axiom 显示决策、Hyprland monitor 验证模式和部署后实机确认维护项。
- 已提交并推送分支 `legion/axiom-4k240-hdr-display`，创建 PR：https://github.com/Thrimbda/dotfiles/pull/86。
