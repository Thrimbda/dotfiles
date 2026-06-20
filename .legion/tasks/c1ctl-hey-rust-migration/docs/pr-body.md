# Implementation Review（实现交付）

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

---

## 交付摘要

- 将 Rust CLI 从 `axiomctl` 改名为 `c1ctl`。
- 让 `c1ctl` 开始承接非 Rofi `hey` 的 Rust 迁移：`path`、`which`、`help`、direct path dispatch、`.foo`、non-Rofi `@namespace`、`wm`、`host`、`theme`、`exec`。
- 保留高风险 mutating `hey` commands 的 Janet delegation。
- 明确 `@rofi` 是 Janet delegation boundary，Rust 不解析或执行 Rofi scripts。

## 范围

**In scope**
- `packages/axiomctl` -> `packages/c1ctl`。
- Axiom host 安装 `c1ctl`。
- 保留 `c1ctl mode cli|desktop|status` 和 `c1ctl reload`。
- Rust foundation dispatcher/path/help/which/exec slice。
- Wiki current-truth 更新。

**Out of scope**
- 删除 Janet `hey`。
- Rust 化 Rofi implementation。
- Rust 化 `sync`、`gc`、`profile`、`pull`、`swap`、hooks、vars。
- Live mode switching 或 graphical reload。

## 主要改动

- 新 package path: `packages/c1ctl`。
- Axiom wiring: `hosts/axiom/default.nix` 通过 `../../packages/c1ctl` 安装。
- Rust CLI 新增 foundation command handling、computed PATH、`HEYSCRIPT`、`HEYDRYRUN`、`HEYDEBUG` env contract。
- Dynamic resolver 拒绝 unsafe path segment，并对 `config/rofi/**` 做最终 guard。
- `.legion/wiki` 把旧 `axiomctl` boundary 标为 historical，当前 truth 改为 `c1ctl` staged migration。

## 验证与审查

- 验证: `.legion/tasks/c1ctl-hey-rust-migration/docs/test-report.md`
- 变更审查: `.legion/tasks/c1ctl-hey-rust-migration/docs/review-change.md`
- 设计一致性: `.legion/tasks/c1ctl-hey-rust-migration/docs/rfc.md` / `.legion/tasks/c1ctl-hey-rust-migration/docs/review-rfc.md`

## 风险与限制

- Live `c1ctl mode cli|desktop/status/reload` 仍需部署后 smoke。
- Delegated mutating commands 不是 Rust parity ports。
- 后续 command-family migration 需要独立 scope 和验证。

## 评审重点

- [ ] `c1ctl` 是否正确 supersede `axiomctl`？
- [ ] First slice 是否足够小且可回滚？
- [ ] `@rofi` delegation 和 traversal guard 是否足够安全？
- [ ] Test report 是否覆盖 env/delegation/bypass 关键风险？

## 证据链接

- plan: `.legion/tasks/c1ctl-hey-rust-migration/plan.md`
- rfc: `.legion/tasks/c1ctl-hey-rust-migration/docs/rfc.md`
- review-rfc: `.legion/tasks/c1ctl-hey-rust-migration/docs/review-rfc.md`
- test-report: `.legion/tasks/c1ctl-hey-rust-migration/docs/test-report.md`
- review-change: `.legion/tasks/c1ctl-hey-rust-migration/docs/review-change.md`
- report-walkthrough: `.legion/tasks/c1ctl-hey-rust-migration/docs/report-walkthrough.md`
