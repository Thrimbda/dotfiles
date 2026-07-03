# Axiom Build And Caelestia Regression - 日志

- 创建任务契约：范围限定为 Axiom build 恢复、Caelestia 启动回归、terminal 字体回归和轻量文档收口。
- 已知用户本地 `flake.lock` 有修改，本任务不主动回滚。
- 诊断结果：Caelestia package 可执行，live `caelestia-session start` 可直接启动；失败根因是 `hey hook startup` 先因 Janet native module ABI mismatch 崩溃，导致 `hyprland-session.target` 和 Caelestia startup hook 没有正常完成。
- 诊断结果：Foot evaluated config 仍写入 `font=FiraCode Nerd Font Mono:size=9.500000`，但 live `fc-match 'FiraCode Nerd Font Mono'` 回退到 `霞鹜新晰黑`；根因是 terminal font package 没进入 NixOS fontconfig package set。
- 实现：`modules/hey.nix` 在 Janet 版本变化时清理并重建 managed `jpm_tree`；`modules/desktop/term/foot.nix` 把 terminal font package 加入 `fonts.packages`；Axiom 保持 host-local Vesktop pnpm override 和 Docker 29 选择。
