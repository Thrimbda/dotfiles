## 交付摘要

- 修复 Axiom build gate：Vesktop 避开 insecure `pnpm-10.29.2`，Docker 切到 Docker 29。
- 修复 switch 后 Caelestia 不自启的根因：Janet 版本变化时清理并重建 managed JPM tree，避免旧 native `.so` 让 `hey hook startup` 崩溃。
- 修复 Foot 字体回退：把 configured terminal font package 加入 NixOS `fonts.packages`。

## 范围

**In scope**

- Axiom host-local package overrides。
- Docker module package option。
- Hey/JPM activation rebuild guard。
- Foot terminal font package exposure。
- 轻量 Legion docs。

**Out of scope**

- 不提交用户本地 `flake.lock` 更新。
- 不重做 Caelestia 架构。
- 不做全量 GUI 自动化 smoke。

## 主要改动

- `hosts/axiom/default.nix`: Axiom Docker 使用 `pkgs.docker_29`；Vesktop 条件式替换 insecure pnpm pin。
- `modules/services/docker.nix`: 增加 `modules.services.docker.package`，并用于 user package 与 daemon package。
- `modules/hey.nix`: Janet version file 变化时清理并重建 managed JPM artifacts。
- `modules/desktop/term/foot.nix`: Foot 启用时把 terminal font package 加入 `fonts.packages`。

## 验证与审查

- 验证: `.legion/tasks/axiom-build-caelestia-regression/docs/test-report.md`
- 变更审查: `.legion/tasks/axiom-build-caelestia-regression/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-build-caelestia-regression/docs/report-walkthrough.md`
- Render: explicit bypass，使用 repo 内 HTML artifact，不新增 Pages workflow。

## 风险与限制

- 需要下一次 Axiom switch/reboot 后做 live smoke，确认 Caelestia 自启动和 Foot 字体恢复。
- 本 PR body 只是 PR 创建输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 评审重点

- [ ] Janet rebuild guard 是否只影响 module-owned JPM tree artifacts。
- [ ] Docker package option 是否保持默认兼容。
- [ ] Foot font exposure 是否符合 terminal font ownership。
