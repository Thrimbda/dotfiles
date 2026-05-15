# SSH Foot Term Compatibility Tasks

## Status

- Current stage: wiki writeback complete; PR lifecycle pending.
- Execution mode: default implementation mode, low-risk hotfix path.
- Worktree: `.worktrees/ssh-foot-term-compat/`
- Branch: `legion/ssh-foot-term-compat`
- Base ref: `origin/master`

## Checklist

- [x] Load Legion workflow and git-worktree-pr requirements.
- [x] Create isolated worktree from `origin/master`.
- [x] Materialize narrow SSH/Foot terminfo compatibility contract.
- [x] Inspect Foot terminal and SSH wrapper configuration.
- [x] Patch the SSH wrapper compatibility boundary.
- [x] Run targeted validation and record test report.
- [x] Run readiness review.
- [x] Generate walkthrough/PR body.
- [x] Write Legion wiki updates.
- [ ] Commit, rebase, push, open PR, enable auto-merge if possible.
- [ ] Follow PR to terminal state, cleanup worktree, refresh main workspace.

## Handoff Notes

- Reported remote error: `/nix/store/...-set-environment:23: can't find terminal definition for foot` and line 48 with the same terminal lookup failure.
- Main workspace had an accidental preliminary edit by the orchestrator; final delivery must happen from this isolated worktree and main workspace must be restored to the base ref.
