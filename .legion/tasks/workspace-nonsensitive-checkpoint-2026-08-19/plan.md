# Workspace Non-Sensitive Checkpoint

## 目标

Deliver the requested versionable non-sensitive workspace state through a merged pull request while preserving local credentials and excluding review-proven regressions.

## 问题陈述

The main workspace is detached and dirty, with desired tracked and untracked content colocated with private keys, password files, API credentials, and nested worktree metadata that must never enter Git history.

## 验收标准

- [ ] All explicitly reviewed safe changes are present in the PR branch, except the three regression clusters the user approved excluding after review.
- [ ] acorn_id_ed25519, acorn_password, resent_key, .worktrees, and the mutable Fcitx profile are absent from the commit and PR diff.
- [ ] Axiom evaluates root, boot, and swap devices as nixos-2t, AXIOM2T, and swap-2t.
- [ ] Diff hygiene and a sensitive-pattern review pass before push.
- [ ] The PR reaches merged state, its worktree is removed, and the main workspace is refreshed without deleting local sensitive files.

## 假设 / 约束 / 风险

- **假设**: The user intentionally requested one checkpoint PR spanning multiple documentation topics, then approved excluding the Hypridle and Legion audit regressions found by review.
- **假设**: Existing changes not authored during the disk migration must be preserved rather than rewritten or reverted.
- **约束**: Use an isolated worktree created from refreshed origin/master.
- **约束**: Never stage, commit, print, or push credential file contents.
- **约束**: Do not modify or remove unrelated local worktrees.
- **约束**: Do not run an Acorn-local Nix build.
- **风险**: Bundling independent documentation changes makes the PR broader than a single-feature change.
- **风险**: A missed credential-like value in a documentation file could leak unless the complete staged diff is reviewed.

## 要点

- Import the safe workspace state without touching excluded local files.
- Verify filesystem labels, diff integrity, and sensitive-data boundaries.
- Commit, rebase, push, merge, clean up, and refresh the main workspace.

## 范围

- Current tracked workspace diff
- Reviewed auth-mini-gateway pin task and wiki evidence
- docs/hey-c1ctl-native-status.md
- Axiom filesystem label migration
- Legion task evidence for this checkpoint

## 非目标 (Non-Goals)

- Do not commit credentials, private keys, local worktrees, or the mutable Fcitx profile.
- Do not rewrite or reinterpret pre-existing workspace changes that the user requested to preserve.
- Do not re-enable duplicate idle ownership or remove merged #166/#167/#168 evidence.
- Do not perform additional disk migration or Windows installation work in this PR.

## 设计索引 (Design Index)

> **Design Source of Truth**: No RFC required; this is a low-risk repository checkpoint and delivery task.

**摘要**:
- Use a strict inclusion list for untracked files and include all tracked changes.
- Review the staged diff and filenames before committing.
- Keep credentials and nested worktrees only in the local main workspace.

## 阶段概览

1. **Import safe state** - Transfer all current tracked changes and reviewed safe untracked documents into the isolated worktree
2. **Verify** - Validate Nix filesystem targets, diff hygiene, and sensitive-data boundaries
3. **Deliver** - Commit, rebase, push, merge the PR, clean up the worktree, and refresh the main workspace

---

*创建于: 2026-08-19 | 最后更新: 2026-08-19*
