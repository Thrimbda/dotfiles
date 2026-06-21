# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 这次修复 Axiom 上 `npx` 或 project-local npm Playwright 启动 Chromium 时缺 `libglib-2.0.so.0` 的问题。
- 系统 `playwright` wrapper 已确认仍可截图，不受回归影响。
- npm Playwright `1.61.0` 下载的 Ubuntu fallback Chromium 已用同一组 nix-ld runtime libraries 启动成功。
- Review 结论为 PASS，没有 blocking finding。
- PR lifecycle 尚未完成。`pr-body.md` 只是 PR 创建输入，不代表 checks、review、merge、cleanup 或主工作区 refresh 已完成。

## Scope

In scope:

- `modules/dev/playwright.nix`
- `.legion/tasks/axiom-playwright-nix-ld-libs/**`

Out of scope:

- 不改 Axiom host-specific enablement。
- 不 pin npm Playwright 版本。
- 不提交下载的 Playwright browser cache、npm cache 或截图。
- 不执行 `nixos-rebuild switch`。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| 任务目标、范围和验收已稳定 | `plan.md` | PASS |
| 设计选择为补 nix-ld runtime libraries | `docs/rfc.md` | PASS |
| 系统 Playwright wrapper 仍能启动 Chromium | `docs/test-report.md` | PASS |
| npm Playwright 下载 browser 在配置库路径下能启动 | `docs/test-report.md` | PASS |
| Axiom NixOS 配置可求值并可 dry-run planning | `docs/test-report.md` | PASS |
| 变更可交付性审查通过 | `docs/review-change.md` | PASS |

## Delivery Path

1. `brainstorm`: 创建并回读 Legion task contract。
2. `design-lite`: 记录 options、decision、rollback 和 verification。
3. `engineer`: 在 Linux 上为 Playwright dev module 添加 nix-ld libraries。
4. `verify-change`: 跑系统 Playwright、npm Playwright、Nix eval 和 dry-run build。
5. `review-change`: 只读审查，结论 PASS。
6. `report-walkthrough`: 生成当前 reviewer handoff。
7. `legion-wiki`: 下一步写入 durable current-truth summary。

## What Changed / What Was Decided

`modules/dev/playwright.nix` 保留 `pkgs.playwright-test` 和 `pw` alias，新增 Linux-only `programs.nix-ld.libraries`。库列表覆盖 Chromium / headless shell 运行需要的 glib、nss、nspr、dbus、atk、pango、libgbm、X11 和图形栈相关库。

设计上没有替换 Nix wrapper，也没有全局 pin npm Playwright。原因是当前故障只发生在 npm/npx 下载的 fallback browser 通过 nix-ld 找库时，补 runtime library path 是最小、可回滚的修复。

## Verification / Review Status

- `playwright screenshot --browser=chromium https://example.com ...`: PASS。
- npm Playwright `1.61.0` 下载 browser 并启动 Chromium: PASS，输出 `149.0.7827.55`。
- `nix eval --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`: PASS。
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`: PASS。
- `docs/review-change.md`: PASS，无 blocking findings。

## Risks and Limits

- Axiom live system 需要后续 `nixos-rebuild switch` 才会持久应用。
- 未来 Playwright browser 版本可能需要更多 runtime libraries。
- npm Playwright 下载 FFmpeg 时出现网络重试，最终第三个镜像成功；这不是实现缺陷。

## Reviewer Checklist

- [ ] 确认 `modules/dev/playwright.nix` 的库列表足以覆盖当前 Chromium fallback browser。
- [ ] 确认 Linux-only guard 不影响 Darwin hosts。
- [ ] 确认 scope 没有引入 npm policy 或 Playwright version policy 变更。
- [ ] 确认验证证据足以支持合并。

## Next Stage

HTML artifact 已生成后应进入 render handoff，随后进行 `legion-wiki` 写回，再按 `git-worktree-pr` lifecycle commit、rebase、push、创建 PR、尝试 auto-merge、跟进 checks/review。当前文档不是 PR 终态证明。
