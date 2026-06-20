# Log: FRP Agenix Deploy

## 2026-06-20

- User requested adding frpc/frps deployment with token authentication: `aliyun-acorn` runs `frps`, `axiom` runs `frpc`, and the shared token must be generated strongly and stored through agenix.
- Legion workflow was requested explicitly after an initial main-worktree implementation. The delivery is normalized into `.worktrees/frp-agenix-deploy` from `origin/master` to avoid mixing unrelated main worktree dirty changes.
- Chosen design keeps token out of Nix store by generating TOML templates with an `@FRP_TOKEN@` placeholder and rendering runtime config from `/run/agenix/frp-token` in `ExecStartPre`.
- Implemented `modules.services.frp`, enabled `frps` on `aliyun-acorn`, enabled `frpc` on `axiom`, and generated matching host-local age secrets.
- Verification passed for secret consistency, both affected host evals, dry-run builds, render-script inspection, frp template syntax, and diff whitespace. See `docs/test-report.md`.
- Review found no blocking issues and identified that `age-secrets-frp-token.service` was not an actual generated unit. Removed the ineffective dependency from the frp service definition before final validation.
- Re-validation after the review fix passed for both host evals, dry-run builds, service ordering, and `git diff --check`. Final implementation review is PASS. See `docs/review-change.md`.
- Generated implementation walkthrough artifacts: `docs/report-walkthrough.md`, `docs/report-walkthrough.html`, and `docs/pr-body.md`. Render handoff recorded as artifact-only/blocker because the repo has no existing Pages PR preview workflow and adding one would expand this task's scope.
- During wiki writeback, found existing `azar` autossh ownership of remote port `2224` on `8.159.128.125`; changed the frp SSH proxy port to `2225` to avoid reusing an active reverse SSH reservation.
- Re-ran verification and final review after changing the frp proxy to `2225`; both passed with no blocking findings.
- Completed wiki writeback with task summary, current FRP tunnel decision, and reusable validation pattern.
- Added `.gitattributes` with `*.age binary` after staged `git diff --check` treated encrypted age bytes as text whitespace.
