# Tasks: Dotfiles Prune and Host Framework Extraction

## Phase 1 - Contract and Design

- [x] 确认旧 task 全删，仅保留本次新 task
- [x] 物化任务契约
- [x] 产出最小 RFC
- [x] 完成 RFC review

## Phase 2 - Isolated Implementation

- [x] 进入 git-worktree-pr envelope
- [x] 删除旧 `.legion/tasks/*`，保留本次 task 与 wiki
- [x] 删除根 `README.md`
- [x] 产出一次性 package module inventory
- [x] 抽取 Axiom/Acorn 的 Cloudflare、autossh、Caelestia 与跨主机 mechanics
- [x] 收敛 Axiom/Acorn default 为 host manifest

## Phase 3 - Verification and Review

- [x] 验证 prune 白名单和 Git diff
- [x] 验证关键 Nix options、生成配置和 systemd/launchd units
- [x] 验证 Axiom/Acorn 代表性配置，不在 Acorn 本机构建
- [ ] 完成 change review

## Phase 4 - Delivery

- [ ] 生成 report walkthrough 与 PR body
- [ ] 创建并跟进 PR/checks/review
- [ ] 完成 Legion wiki writeback
- [ ] PR 达到终态并清理 worktree
