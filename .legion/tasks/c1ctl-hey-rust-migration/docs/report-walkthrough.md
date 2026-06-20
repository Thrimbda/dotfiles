# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本 PR 将 `axiomctl` 正式改名为 `c1ctl`，并把第一批非 Rofi `hey` foundation 行为迁入 Rust。
- Rust 现在拥有 `path`、`which`、`help`、direct path dispatch、`.foo`、non-Rofi `@namespace`、`wm`、`host`、`theme`、`exec`。
- 高风险 mutating 命令仍委托到 Janet `hey`，包括 `sync`、`gc`、`profile`、`pull`、`swap`、hooks、vars。
- `@rofi` 是精确委托边界，Rust 不解析也不执行 Rofi scripts；绕过形式和 traversal 已有负向验证。
- 验证和 review 都是 PASS，PR lifecycle 仍未完成。

## Scope

In scope:

- `packages/axiomctl` -> `packages/c1ctl`。
- Axiom host 安装 `c1ctl`。
- 保留 Axiom mode/status/reload 行为。
- 实现 Rust `hey` foundation slice。
- 更新 Axiom README、Legion task docs、wiki current truth。

Out of scope:

- 不删除 Janet `hey`。
- 不迁移 Rofi implementation。
- 不 Rust 化 `sync`、`gc`、`profile`、`pull`、`swap`、hooks、vars。
- 不执行 live mode switch 或 graphical reload。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| Contract 稳定且选择 staged migration | `plan.md`, `docs/rfc.md` | PASS |
| RFC design gate 通过 | `docs/review-rfc.md` | PASS |
| `c1ctl` package builds | `docs/test-report.md` package build | PASS |
| CLI foundation 和 env contract 有安全验证 | `docs/test-report.md` CLI behavior section | PASS |
| Axiom 安装 `c1ctl` 且不安装 `axiomctl` | `docs/test-report.md` Axiom package eval | PASS |
| Rofi bypass/traversal 被阻止 | `docs/test-report.md`, `docs/review-change.md` | PASS |
| Implementation review 通过 security lens | `docs/review-change.md` | PASS |
| Wiki current truth 已更新 | `.legion/wiki/decisions.md`, `.legion/wiki/patterns.md`, `.legion/wiki/maintenance.md` | PASS |

## What Changed / What Was Decided

- `c1ctl` 是新的 durable Rust control CLI。
- Axiom SSH-only mode 现在通过 `c1ctl mode cli` / `c1ctl mode desktop` 表达。
- Rust foundation slice 接管安全可验证的 dispatcher/introspection/path 行为。
- Unported mutating command families 继续委托给 Janet `hey`，直到后续 scoped parity tasks。
- `@rofi` 保持在 Janet 侧，Rust 对 malformed namespace、path-like namespace 和 traversal 均拒绝。

## Verification / Review Status

- `rustfmt --check`: PASS，带已知 non-fatal Nix eval-cache warning。
- `nix build .#c1ctl`: PASS。
- CLI behavior/env/delegation checks: PASS。
- Axiom package eval: PASS。
- Axiom toplevel dry-run: PASS，带 transient cache timeout retry warnings。
- `git diff --check`: PASS。
- `review-change`: PASS，security lens applied。

## Risks and Limits

- Live `c1ctl mode cli`、`c1ctl mode desktop`、`c1ctl status`、`c1ctl reload` 仍是部署后 smoke。
- 高风险 `hey` commands 仍是 delegation，不是 Rust parity port。
- 后续迁移每个 command family 都需要独立 scope、parity checks 和 rollback 证据。

## Reviewer Checklist

- [ ] `c1ctl` naming/package/wiring 是否符合新 durable CLI direction？
- [ ] Rust foundation slice 是否足够小且可验证？
- [ ] `@rofi` delegation 和 traversal guard 是否满足安全边界？
- [ ] Delegated mutating commands 保留 Janet 是否符合 staged rollout？
- [ ] Post-deploy smoke 是否已清楚留到 maintenance？

## Next Stage

HTML artifact 已生成在 `docs/report-walkthrough.html`。本任务显式选择 artifact-only/local render，不新增 GitHub Pages preview workflow；原因是 Pages PR preview 配置不属于本 CLI migration scope。随后继续 PR lifecycle：commit、rebase、push、open PR、checks/review、merge、cleanup、main refresh。
