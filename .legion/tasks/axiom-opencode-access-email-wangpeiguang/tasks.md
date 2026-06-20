# Axiom Opencode Access Email Allowlist - Tasks

## Current Status

- Phase: git-pr-lifecycle
- Risk: low for repo docs, medium for live Cloudflare policy update
- Mode: default implementation mode with low-risk repo path; Cloudflare API action gated by credential availability

## Checklist

- [x] 收敛 task contract。
- [x] 进入 `git-worktree-pr` envelope。
- [x] 更新 repo allowlist truth source。
- [x] 检查 Access-capable Cloudflare token 是否可用且不输出 secret。
- [x] 如 token 可用，更新并读回验证 `opencode-axiom.0xc1.space` Access allow policy。
- [x] 如 token 不可用，记录 Cloudflare 控制面待手工/API 执行。
- [x] 运行验证并写 `docs/test-report.md`。
- [x] 写 `docs/review-change.md`。
- [x] 写 `docs/report-walkthrough.md` 和必要 PR evidence。
- [x] 更新 `.legion/wiki` 当前真源。

## Done Criteria

- Repo 真源明确包含 `wangpeiguangwpg@gmail.com`。
- Cloudflare live state 已验证更新，或阻塞原因被明确记录且没有伪造完成声明。
- 无 secret 泄露，无 broad/domain/everyone/bypass policy 扩大。
