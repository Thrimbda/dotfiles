# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务修复 Axiom build gate，并处理 switch 后 Caelestia 不自启与 Foot 字体回退问题。
- Caelestia 根因是 `hey hook startup` 因 Janet native module ABI mismatch 崩溃，不是 Caelestia package 本身不可执行。
- Foot 字体根因是 terminal font package 没进入 NixOS fontconfig package set，导致 `FiraCode Nerd Font Mono` 匹配到中文 fallback。
- Review 结论为 PASS。

## Scope

In scope:

- Axiom Vesktop pnpm override 和 Docker 29 package 选择。
- `modules.services.docker.package` 选项。
- `modules/hey.nix` 的 Janet 版本变化 rebuild guard。
- `modules/desktop/term/foot.nix` 的 terminal font package exposure。

Out of scope:

- 不提交用户已有 `flake.lock` 更新。
- 不重写 Caelestia 架构。
- 不做全量 GUI smoke 自动化。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| Axiom toplevel 可 build | `docs/test-report.md` | PASS |
| startup hook 根因已定位 | `docs/test-report.md` live 观察 | PASS |
| review 无 blocking finding | `docs/review-change.md` | PASS |
| 未用 insecure allowlist | diff + `docs/review-change.md` | PASS |

## What Changed / What Was Decided

- Axiom 使用 Docker 29，避免 unmaintained Docker 28。
- Vesktop override 只在当前 nixpkgs 版本暴露 `pnpm_10_29_2` 参数时替换为 `pkgs.unstable.pnpm_10`，兼容旧 lock。
- Janet 版本变化时清理并重建 managed JPM tree，避免旧 `.so` 阻断 `hey hook startup`。
- Foot terminal font package 加入 `fonts.packages`，让 fontconfig cache 包含 configured terminal font。

## Verification / Review Status

- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'` 通过。
- merged user activation script 通过 `zsh -n`。
- `git diff --check` 通过。
- `docs/review-change.md` 为 PASS。

## Risks and Limits

- 仍需下一次 switch 后确认 live Caelestia 自启动和 Foot 字体恢复。
- 本任务没有提交用户本地 `flake.lock` 更新。

## Reviewer Checklist

- [ ] 确认 Docker package option 的默认行为保持兼容。
- [ ] 确认 Janet rebuild guard 删除范围足够窄。
- [ ] 确认 Foot font package exposure 符合 terminal font ownership。

## Next Stage

Render handoff: explicit bypass。用户要求轻量文档，本任务不新增 Pages workflow 或发布 preview URL；repo 内 HTML artifact 作为本地审阅文件。

PR-backed lifecycle 继续：提交、rebase、push、创建 PR、跟进 checks/review。`pr-body.md` 只是 PR 创建输入，不代表 PR lifecycle 完成。
