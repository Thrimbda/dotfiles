# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务把 Axiom 本机 Rust CLI 从 `axiom-mode` 重命名并扩展为 `axiomctl`。
- `axiomctl mode cli` / `desktop` / `status` 保留原有 systemd target 语义，顶层 `cli` / `desktop` / `status` 也作为便捷别名保留。
- 新增的 `axiomctl reload` 只是固定 argv 调用现有 `hey reload` hook path，不引入 Rofi、shell eval 或动态脚本派发。
- 验证与 review 均为 PASS，PR lifecycle 尚未完成。

## Scope

In scope:

- Rename `packages/axiom-mode` to `packages/axiomctl`.
- Update Axiom host installation and README docs.
- Keep mode switching behavior while moving the durable entrypoint to `axiomctl mode ...`.
- Add the bounded `reload` bridge to the existing `hey reload` path.
- Update current Legion wiki truth for the renamed host-control CLI.

Out of scope:

- No broad `hey` rewrite.
- No Rofi command migration.
- No Caelestia-owned desktop control replacement.
- No change to `axiom-cli.target` or remote access service policy.

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| `axiomctl` package builds and is exposed as `.#axiomctl` | `docs/test-report.md` package build section | PASS |
| Help output shows `mode`, aliases, `status`, and `reload` | `docs/test-report.md` help output section | PASS |
| Axiom installs `axiomctl`, not `axiom-mode` | `docs/test-report.md` Axiom host eval section | PASS |
| `axiom-cli.target` relationships remain unchanged | `docs/test-report.md` Axiom host eval section | PASS |
| Current docs no longer reference stale package names | `docs/test-report.md` stale current-reference check | PASS |
| Security-sensitive command paths use fixed argv | `docs/review-change.md` security lens | PASS |

## What Changed / What Was Decided

`axiomctl` is now the durable Axiom host-control CLI. It owns a small set of typed, fixed behavior: system mode switching, mode status, and a reload bridge. Broad dotfiles workflows still belong to `hey`, and Rofi-era commands stay out of this CLI.

The host injects the evaluated `hey` script path into `axiomctl` for reload, while `systemctl` remains injected by the package derivation. That keeps deployed command lookup explicit for the Axiom host.

## Verification / Review Status

- Verification: PASS in `docs/test-report.md`.
- Change review: PASS in `docs/review-change.md`.
- Security lens: applied because privileged systemd target switching is in scope. No blocker found.

## Risks and Limits

- Live `axiomctl mode cli` / `desktop` were not run because they would isolate system targets.
- Live `axiomctl reload` was not run because it should be exercised inside the deployed Axiom graphical session.
- Historical task docs still mention `axiom-mode` as history; current truth was updated in README and Legion wiki current pages.

## Reviewer Checklist

- [ ] Confirm `axiomctl` is the desired command name.
- [ ] Confirm the command surface is intentionally narrow and does not duplicate `hey`.
- [ ] Confirm `reload` should remain a fixed bridge to `hey reload` rather than a Rust reimplementation of hooks.
- [ ] Confirm the validation evidence is sufficient for repository-level merge, with live target switching left as post-deploy smoke.

## Next Stage

PR-backed lifecycle remains pending. The HTML artifact should be handed to `pr-html-render` for preview handling when available; then the task proceeds through wiki writeback, commit, rebase, push, PR creation, checks/review follow-up, cleanup, and main refresh.
