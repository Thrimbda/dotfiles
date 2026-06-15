# Walkthrough：Axiom 4K 240Hz HDR 屏幕设置

## 模式

implementation。

## 变更摘要

- 将 Axiom Hyprland monitor mode 从 `3840x2160@60` 改为 `3840x2160@240`，优先解决当前仍是 60Hz 的问题。
- 保留 `position = "0x0"` 和 `scale = 1.5`，不改变 Axiom 屏幕布局和缩放。
- 为共享 Hyprland monitor 模块新增可选字段：`bitdepth`、`cm`、`sdrbrightness`、`sdrsaturation`。
- 未设置高级字段时仍生成旧 `monitor = output,mode,position,scale` 格式；只有设置 HDR/色彩管理相关字段时才生成 `monitorv2` 块。
- Axiom 本次不默认启用 HDR，不移除 `render.cm_enabled = false`；注释说明 HDR 低于 240Hz，且色彩管理需要后续实机 DPMS/恢复稳定性验证。

## 关键文件

- `hosts/axiom/default.nix`：Axiom 从 60Hz 改为 240Hz，并补充 HDR/色彩管理保护注释。
- `modules/desktop/hyprland.nix`：新增 monitor 高级字段 option 和 `monitorv2` 生成路径。
- `.legion/tasks/axiom-4k240-hdr-display/docs/test-report.md`：记录 Axiom monitor 生成结果和补充验证。
- `.legion/tasks/axiom-4k240-hdr-display/docs/review-change.md`：记录 PASS 评审结论与残余风险。

## 验证证据

- `nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/monitors.conf".text'` 通过，输出 `monitor = ,3840x2160@240,0x0,1.500000`。
- `git diff --check` 通过。
- `azar` 的 monitor 输出仍保持旧 `monitor = ...` 格式，证明未设置高级字段的既有 host 不会被默认切到 `monitorv2`。
- 使用 `extendModules` 临时设置 `output = "DP-1"`、`bitdepth = 10`、`cm = "hdr"`、`sdrbrightness = 1.2`、`sdrsaturation = 0.98`，验证高级字段能生成 `monitorv2` 块。

## 评审结论

`docs/review-change.md` 结论为 PASS。无阻塞问题，未命中安全触发条件。

## 残余风险与后续

- 仓库验证只能证明配置生成结果；真实 240Hz 是否点亮仍需要在 Axiom 实机 Hyprland 会话中运行 `hyprctl monitors` 确认。
- HDR 运行态仍未启用。后续如要开启，需要先重新考虑 `cm_enabled = false`，并验证 DPMS/恢复稳定性。
