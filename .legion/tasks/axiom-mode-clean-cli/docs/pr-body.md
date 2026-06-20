# Implementation Review

> 本 PR body 只是 PR 创建输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 把 `axiom-mode` 从 `hosts/axiom/default.nix` 的内联 shell 字符串迁移为 `packages/axiom-mode` Rust CLI。
- host 现在只通过 `pkgs.callPackage ../../packages/axiom-mode {}` 安装命令。
- `axiom-cli.target` 和用户可见行为不变。

## 范围

**In scope**

- `packages/axiom-mode/**`: 新增 Rust crate。
- `hosts/axiom/default.nix`: 删除内联 `writeShellScriptBin`，改为引用 package。
- `.legion/tasks/axiom-mode-clean-cli/**` 和 wiki 写回。

**Out of scope**

- systemd target 语义调整。
- 远程访问或电源策略调整。
- 引入外部 Rust dependency 或通用 CLI framework。

## 验证与审查

- 验证: `.legion/tasks/axiom-mode-clean-cli/docs/test-report.md`
- 变更审查: `.legion/tasks/axiom-mode-clean-cli/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-mode-clean-cli/docs/report-walkthrough.md`

## 评审重点

- [ ] `axiom-mode` 是否已从 host 内联脚本变成可维护的 Rust package？
- [ ] 命令行为是否保持兼容？
- [ ] 是否没有改变 `axiom-cli.target` 或远程访问服务语义？
