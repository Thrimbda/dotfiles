# RFC：Axiom 4K 240Hz HDR 屏幕设置

## 背景

Axiom 当前使用 Hyprland，主机配置把 monitor 模式写成 `3840x2160@60`，用户也明确反馈现在看到的实际状态是 60Hz。新的目标屏幕是 4K 240Hz，因此基础显示模式应更新为 `3840x2160@240`，且 240Hz 优先级高于 HDR。

HDR 需要额外谨慎处理。当前 Hyprland 文档给出的 HDR monitor 配置包含 `bitdepth = 10`、`cm = hdr`，并可选设置 `sdrbrightness` 与 `sdrsaturation`。但是 Axiom 当前在 `extraConfig` 中显式关闭了 `render.cm_enabled`，注释说明这是为了规避 Hyprland 0.53.x 色彩管理在 DPMS/恢复时崩溃。直接删除这个保护并宣称 HDR 已启用，会把显示稳定性风险转移到用户运行态。

## 方案选项

### 方案 A：只改 4K 240Hz，不扩展 HDR 字段

优点是最小且稳定；缺点是没有为 HDR 留出明确配置路径，也无法满足“如果能有 HDR 就太好了”的长期需求。

### 方案 B：立即启用 HDR，并移除 `cm_enabled = false`

优点是最接近完整 HDR；缺点是会直接撤销现有 DPMS/恢复稳定性 workaround，而本任务无法在仓库验证中证明该崩溃已经消失。

### 方案 C：设置 4K 240Hz，并扩展 monitor 生成器以支持 HDR 字段；Axiom 保守保留色彩管理保护

优点是完成确定的 240Hz 目标，同时让仓库具备表达 HDR monitor 字段的能力；缺点是 Axiom 运行态 HDR 仍需用户后续在实机上移除/调整 `cm_enabled = false` 后验证。

## 推荐方案

采用方案 C，但实施顺序以 240Hz 为第一优先级。

理由：240Hz 是明确需求，并且当前问题就是仍停留在 60Hz；HDR 是低优先级期望能力，但当前存在明确的稳定性保护与其冲突。推荐方案把可验证的 240Hz 配置、可选 HDR 配置结构和不可替代的实机验证分开，不把“已具备 HDR 配置字段”误写成“运行态 HDR 已稳定开启”。

## 设计

- 在共享 Hyprland monitor submodule 中新增可选字段：`bitdepth`、`cm`、`sdrbrightness`、`sdrsaturation`。
- 生成 `hypr/monitors.conf` 时，未设置高级字段的 monitor 继续使用既有 `monitor = output,mode,position,scale` 行；只有设置了 HDR/色彩管理相关高级字段时，才生成可承载 `bitdepth`、`cm`、`sdrbrightness`、`sdrsaturation` 的 `monitorv2` 块。
- 将 Axiom 的 `mode` 更新为 `3840x2160@240`，保留 `position = "0x0"` 和 `scale = 1.5`。
- 不在本任务中移除 Axiom 的 `render.cm_enabled = false`。在配置注释中明确：HDR 字段的运行态启用需要重新开启 Hyprland 色彩管理并在 DPMS/恢复后验证稳定性。

## 回滚

- 如果 240Hz 在实机上无法点亮或不稳定，将 Axiom monitor mode 改回 `3840x2160@60` 或 `preferred`。
- 如果新增 monitor 字段生成导致 Hyprland 配置问题，移除 Axiom 对 HDR 字段的使用；共享模块可保留，因为默认空值不改变旧配置输出。
- 如果后续开启 HDR 触发 DPMS/恢复崩溃，恢复 `render.cm_enabled = false` 并移除 Axiom monitor 的 HDR 字段。

## 验证计划

- 运行 Nix 格式检查或求值检查，证明 Nix 语法有效。
- 对 Axiom 配置求值，检查 `home-manager.users.c1.home.file.".config/hypr/monitors.conf".text` 或等价生成结果包含 `3840x2160@240`。
- 若条件允许，在 Axiom 实机 Hyprland 会话中运行 `hyprctl monitors` 确认刷新率，并在后续 HDR 实验时确认 DPMS/恢复稳定性。

## 当前结论

设计通过后进入实现：优先落地 4K 240Hz 和可选 HDR 字段生成；Axiom 默认不撤销色彩管理稳定性保护。
