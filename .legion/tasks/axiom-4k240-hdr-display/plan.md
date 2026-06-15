# Axiom 4K 240Hz HDR 屏幕设置

## 目标

把 Axiom 工作站的显示链路从当前 60Hz 配置调整到新的 4K 240Hz 屏幕。HDR 是次要目标，只在 Hyprland/NixOS 配置可以正确表达、且不会默默移除既有稳定性保护的前提下做低优先级支持。

## 问题

Axiom 当前只声明了一个 Hyprland 屏幕，模式是 `3840x2160@60`，缩放是 `1.5`。现在硬件已经换成 4K 240Hz 屏幕，合成器应该请求 `3840x2160@240`。HDR 是期望能力，但当前 Axiom 配置里显式设置了 `render.cm_enabled = false`，原因是规避 Hyprland 0.53.x 色彩管理在 DPMS/恢复时崩溃。HDR 依赖色彩管理和 10-bit 输出，所以本任务不能在保留该保护的同时假装 HDR 已经完整启用。

## 验收标准

- Axiom 的 Hyprland 屏幕模式请求为 `3840x2160@240`，并保留现有位置与缩放；这是本任务最高优先级。
- 共享 Hyprland 屏幕模块可以表达当前 Hyprland 文档中的 HDR 相关字段：`bitdepth`、`cm`、`sdrbrightness`、`sdrsaturation`。
- Axiom 的 HDR 状态在配置中明确：要么启用色彩管理和 HDR，要么保留关闭状态并清楚说明原因与既有 DPMS/恢复稳定性 workaround 有关。
- 未使用 HDR 字段的其他主机生成的 Hyprland 屏幕配置保持有效且行为不变。
- 通过 Nix 求值/格式类验证证明改动后的配置语法有效。

## 假设

- Axiom 当前只有一个主要屏幕，继续沿用现有 Hyprland 输出匹配方式。
- 屏幕、线材和 GPU 输出链路会向 Hyprland 暴露有效的 `3840x2160@240` 模式。
- 现有色彩管理崩溃 workaround 在没有真实运行态验证前仍然视为有效约束。
- 仓库内验证可以证明 Nix 与生成配置的形态正确，但真实 240Hz/HDR 行为仍需要在 Axiom 实机 Hyprland 会话中确认。

## 约束

- 改动范围收敛到 Axiom 显示设置，以及为表达这些设置所需的共享 Hyprland 屏幕生成器。
- 不扩展到 GPU 驱动、内核、EDID override、桌面主题、壁纸或 Caelestia 重新设计。
- 不在没有说明风险和验证需求的情况下，启用与现有 `cm_enabled = false` 保护冲突的 HDR。
- 保留其他主机现有屏幕默认值和行为。

## 范围

- 将 `hosts/axiom/default.nix` 的屏幕模式从 60Hz 更新到 240Hz。
- 扩展 `modules/desktop/hyprland.nix` 的屏幕选项和生成逻辑，使其支持可选 HDR/色彩管理字段。
- 记录本地验证结果，以及实际 HDR/240Hz 仍需在 Axiom 实机确认的后续事项。

## 非目标

- 如果当前工作区无法访问真实 Axiom 图形会话，不保证完成物理运行态验证。
- 不做内核、NVIDIA、EDID 或线材链路调优。
- 不新增屏幕配置切换器或热插拔自动化。
- 不清理大型 Axiom host 文件中的无关内容。

## 推荐方向

- 把 4K 240Hz 作为必须完成且最高优先级的改动：将 Axiom 的 monitor mode 从当前 `3840x2160@60` 设置为 `3840x2160@240`。
- 为共享 Hyprland 模块增加可选 monitor 属性，使 HDR 相关字段只在配置时生成。
- Axiom 的 HDR 采取保守策略：除非明确移除现有色彩管理保护，否则只能把 HDR 能力表达为“已具备配置结构/可切换”，不能宣称运行态 HDR 已开启。
- 优先采用最小 Nix 改动，不引入新的显示抽象层。

## 阶段拆分

1. 契约与轻量设计：记录范围、风险和 HDR 约束。
2. 实现：更新 monitor schema/generator，并更新 Axiom 主机显示设置。
3. 验证：运行聚焦的 Nix 验证，并在可行时检查生成的 monitor 配置。
4. 收口：写入验证证据、变更评审、walkthrough 和 wiki 回写。

## 风险

- 中风险：240Hz 可能暴露只有实机才能验证的线材、GPU 输出或屏幕模式问题。
- 中风险：HDR 需要 Hyprland 色彩管理，而 Axiom 当前为了规避已知崩溃显式关闭色彩管理。
- 低风险：扩展 monitor 选项本身是局部改动，但如果可选字段生成错误，可能破坏 Hyprland 配置，需要通过验证覆盖。
