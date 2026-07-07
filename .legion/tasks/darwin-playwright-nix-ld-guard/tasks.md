# Darwin Playwright Nix-LD Guard Tasks

## Status

Current phase: PR created / merge pending

## Checklist

- [x] 收敛 task contract
- [x] 创建 design-lite
- [x] 修改 `modules/dev/playwright.nix`
- [x] 验证 Darwin build 不再触发 `programs.nix-ld` eval 错误
- [x] 验证 Linux nix-ld intent 仍保留
- [x] 编写 `docs/test-report.md`
- [x] 编写 `docs/review-change.md`
- [x] 编写 `docs/report-walkthrough.md`
- [x] 更新 Legion wiki
- [ ] 提交、推送、创建 PR 并合并（PR: https://github.com/Thrimbda/dotfiles/pull/128）
- [ ] 清理 worktree 并刷新主工作区
- [ ] 重试 `sudo darwin-rebuild switch --flake .#charlie`
