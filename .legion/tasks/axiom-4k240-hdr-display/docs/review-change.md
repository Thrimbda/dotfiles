# 变更评审：Axiom 4K 240Hz HDR 屏幕设置

## 结论

PASS。

## 阻塞问题

无。

## 审查要点

- Scope 合规：改动只涉及 Axiom 屏幕设置、共享 Hyprland monitor 生成器，以及本任务 Legion 文档。
- 240Hz 主目标满足：`hosts/axiom/default.nix` 已从 `3840x2160@60` 改为 `3840x2160@240`，验证报告中的 `nix eval` 输出证明最终 `monitors.conf` 会请求 240Hz。
- HDR 优先级处理正确：Axiom 没有默认设置 `bitdepth/cm`，也没有移除 `render.cm_enabled = false`；注释明确 HDR 低于 240Hz，后续需要实机重测色彩管理和 DPMS/恢复稳定性。
- 默认兼容性可接受：未设置高级字段时仍生成旧 `monitor = ...` 行；`azar` 求值确认既有 host 未被切到 `monitorv2`。
- 高级字段路径有求值证据：临时 `extendModules` 覆盖验证了 `bitdepth`、`cm`、`sdrbrightness`、`sdrsaturation` 可以生成 `monitorv2` 块。

## 安全视角

未命中安全触发条件。本次不涉及认证、权限、密钥、网络边界、用户输入进入特权路径或数据暴露。

## 残余风险

- 仓库验证只能证明 Nix 生成配置正确；真实 240Hz 是否点亮仍要在 Axiom 实机 Hyprland 会话中用 `hyprctl monitors` 确认。
- HDR 运行态仍未启用；后续如果要开启，需要先决定是否移除 `cm_enabled = false`，并验证 DPMS/恢复不再触发 Hyprland 色彩管理崩溃。
