# 任务清单：Axiom 4K 240Hz HDR 屏幕设置

## 状态

- 当前阶段：Legion 阶段链完成，等待 Git/PR lifecycle。
- 用户追加优先级：先解决当前仍是 60Hz 的问题；HDR 优先级低于 240Hz。
- 风险等级：中风险。原因是 HDR 与现有 Hyprland 色彩管理稳定性 workaround 冲突，且真实显示模式需要实机会话确认。

## 检查项

- [x] 建立稳定任务契约，覆盖目标、验收、范围、假设、约束、风险、非目标和阶段拆分。
- [x] 基于 Axiom 现有色彩管理保护，确定最终 HDR 策略。
- [x] 完成 RFC 审查并确认可实现、可验证、可回滚。
- [x] 更新 Hyprland monitor 模块，在不改变默认行为的前提下支持可选 HDR/色彩管理字段。
- [x] 将 Axiom monitor mode 更新为 `3840x2160@240`。
- [x] 运行聚焦 Nix 验证，并把证据写入 `docs/test-report.md`。
- [x] 做变更回归评审，并写入 `docs/review-change.md`。
- [x] 生成面向 reviewer 的 walkthrough 和 PR body 文档。
- [x] 完成 Legion wiki 收口回写。

## 范围内文件

- `hosts/axiom/default.nix`
- `modules/desktop/hyprland.nix`
- `.legion/tasks/axiom-4k240-hdr-display/**`

## 范围外事项

- GPU、内核或 EDID 调优。
- 显示器固件或 OSD 设置。
- 新增 monitor profile 管理器。
- 无关的 Axiom 服务清理。
