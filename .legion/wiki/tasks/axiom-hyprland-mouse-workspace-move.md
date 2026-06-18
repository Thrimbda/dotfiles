# axiom-hyprland-mouse-workspace-move

## Metadata

- `task-id`: `axiom-hyprland-mouse-workspace-move`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `2026-06-18`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

Axiom 生成的 Hyprland keybind 现在提供鼠标窗口操作：`SUPER + left mouse drag` 移动窗口，`SUPER + right mouse drag` 调整窗口大小，`SUPER+SHIFT + wheel down/up` 将当前窗口移动到相邻 workspace。该任务没有改 Caelestia Shell / Quickshell QML，也没有接管 second-monitor workspace 任务或改变 workspace 编号。

当前有效结论是：普通应用窗口的鼠标移动/缩放/相邻 workspace 移动由 Hyprland 原生 binding 承担；Caelestia workspace UI 仍只是 shell UI，未实现 drag/drop。生成配置通过 targeted Nix eval、`git diff --check` 和 assembled `Hyprland --verify-config` 验证。

## Reusable Decisions

- Axiom 普通窗口的鼠标移动/缩放使用生成的 Hyprland `bindm`，不通过 Caelestia/Quickshell QML 实现。
- Axiom 鼠标滚轮 workspace 移动方向与 Caelestia workspace scroll 保持一致：wheel down -> `+1`，wheel up -> `-1`。
- 修改生成的 Hyprland keybind 后，至少验证 generated keybind text，并优先运行 assembled `Hyprland --verify-config` 覆盖 parser surface。

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-hyprland-mouse-workspace-move/plan.md`
- `log`: `.legion/tasks/axiom-hyprland-mouse-workspace-move/log.md`
- `tasks`: `.legion/tasks/axiom-hyprland-mouse-workspace-move/tasks.md`
- `test-report`: `.legion/tasks/axiom-hyprland-mouse-workspace-move/docs/test-report.md`
- `review`: `.legion/tasks/axiom-hyprland-mouse-workspace-move/docs/review-change.md`
- `report`: `.legion/tasks/axiom-hyprland-mouse-workspace-move/docs/report-walkthrough.md`

## Notes

- Live physical mouse behavior remains a post-deploy Axiom Hyprland session smoke check.
- Caelestia layer-shell surfaces may still consume pointer events over their own UI regions; this is expected and unchanged.
