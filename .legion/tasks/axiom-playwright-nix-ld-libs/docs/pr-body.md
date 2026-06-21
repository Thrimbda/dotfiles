# Implementation Review（实现交付）

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 修复 Axiom 上 npm/npx Playwright 下载的 Ubuntu fallback Chromium 因 `libglib-2.0.so.0` 缺失而无法启动的问题。
- 保留现有 Nix-packaged `playwright` wrapper，不改变 Playwright 全局版本策略。
- 在 Linux 且 Playwright dev module 启用时，把 Chromium 运行所需共享库加入 `programs.nix-ld.libraries`。

## 范围

**In scope**

- `modules/dev/playwright.nix`
- `.legion/tasks/axiom-playwright-nix-ld-libs/**`

**Out of scope**

- 不改 Axiom host-specific enablement。
- 不 pin npm Playwright 版本。
- 不提交下载的 Playwright browser cache、npm cache 或截图。
- 不执行 `nixos-rebuild switch`。

## 主要改动

- 新增 Linux-only `programs.nix-ld.libraries` block。
- 库列表覆盖 glib、nss、nspr、dbus、atk、pango、libgbm、X11 和图形栈相关运行库。
- 保持 `pkgs.playwright-test` 和 `pw = "playwright"` alias 不变。

## 验证与审查

- 验证: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/test-report.md`
- 变更审查: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/review-change.md`
- 设计记录: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/rfc.md`
- Walkthrough: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/report-walkthrough.html`

验证结论:

- `playwright screenshot --browser=chromium https://example.com ...`: PASS。
- npm Playwright `1.61.0` downloaded browser launch: PASS，输出 `149.0.7827.55`。
- `nix eval --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`: PASS。
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`: PASS。
- `review-change`: PASS，无 blocking findings。

## 风险与限制

- Axiom live system 需要后续 `nixos-rebuild switch` 才会持久应用。
- 未来 Playwright browser 版本可能需要追加 runtime libraries。
- npm Playwright 下载 FFmpeg 时遇到网络重试，最终成功，不影响实现结论。

## 评审重点

- [ ] 变更是否符合 task contract 与 scope？
- [ ] 库列表是否覆盖当前 Chromium fallback browser 所需运行库？
- [ ] Linux-only guard 是否避免影响 Darwin？
- [ ] 验证证据是否足以支持合并？

## 证据链接

- plan: `.legion/tasks/axiom-playwright-nix-ld-libs/plan.md`
- design-lite: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/rfc.md`
- test-report: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/test-report.md`
- review-change: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/review-change.md`
- report-walkthrough: `.legion/tasks/axiom-playwright-nix-ld-libs/docs/report-walkthrough.html`
