> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要
- 将 Axiom 本机 Rust CLI 从 `axiom-mode` 重命名为 `axiomctl`。
- 保留原有 desktop/CLI systemd target 切换语义，并将正式入口调整为 `axiomctl mode ...`。
- 新增 `axiomctl reload`，只作为固定 argv 桥接到现有 `hey reload` hook path。

## 范围
**In scope**
- Rename `packages/axiom-mode` to `packages/axiomctl`.
- Update Axiom host package wiring and README usage.
- Update current Legion wiki truth for the renamed CLI boundary.
- Validate package build, help output, host eval, toplevel dry-run, stale references, and diff whitespace.

**Out of scope**
- No broad `hey` rewrite.
- No Rofi command migration.
- No Caelestia desktop-control replacement.
- No change to `axiom-cli.target` or remote access services.

## 主要改动
- `packages/axiomctl`: new renamed Rust package and command parser.
- `hosts/axiom/default.nix`: installs `axiomctl` and injects the evaluated `hey` path for reload.
- `hosts/axiom/README.org`: documents `axiomctl status`, `axiomctl mode cli`, `axiomctl mode desktop`, and `axiomctl reload`.
- `.legion/wiki/*`: updates current truth from `axiom-mode` to `axiomctl`.

## 验证与审查
- 验证: `.legion/tasks/axiomctl-cli-consolidation/docs/test-report.md`
- 变更审查: `.legion/tasks/axiomctl-cli-consolidation/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiomctl-cli-consolidation/docs/report-walkthrough.md`

## 风险与限制
- Live `axiomctl mode cli` / `desktop` target isolation was not run in this environment.
- Live `axiomctl reload` should be smoke-tested after deployment in the Axiom graphical session.
- Historical task docs still mention `axiom-mode`; current truth pages and active host docs were updated.

## 评审重点
- [ ] `axiomctl` 是否是合适的新 CLI 名称？
- [ ] `reload` 作为固定桥接而不是重写 `hey hook` 是否符合维护边界？
- [ ] 变更是否避免了 Rofi 和 broad `hey` scope creep？
- [ ] 验证证据是否足以支持 repository-level merge？

## 证据链接
- plan: `.legion/tasks/axiomctl-cli-consolidation/plan.md`
- test-report: `.legion/tasks/axiomctl-cli-consolidation/docs/test-report.md`
- review-change: `.legion/tasks/axiomctl-cli-consolidation/docs/review-change.md`
- report-walkthrough: `.legion/tasks/axiomctl-cli-consolidation/docs/report-walkthrough.md`
