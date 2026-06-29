# Theme Shell Terminal Migration Tasks

## Status

- Current stage: wiki writeback complete; PR lifecycle pending.
- Execution mode: default implementation mode, low-risk ownership migration path.
- Worktree: `.worktrees/theme-shell-terminal-migration/`
- Branch: `legion/theme-shell-terminal-migration-theme-config`
- Base ref: `origin/master`

## Checklist

- [x] Protect main workspace diff in a stash.
- [x] Create isolated Legion worktree from `origin/master`.
- [x] Replay the approved shell/terminal migration diff into the worktree.
- [x] Materialize Legion task contract.
- [x] Run targeted verification and record test report.
- [x] Run readiness review and record result.
- [x] Generate walkthrough and PR body.
- [x] Write Legion wiki updates.
- [ ] Commit scoped files on the Legion branch.
- [ ] Rebase branch on latest `origin/master` and push.
- [ ] Open PR and attempt auto-merge.
- [ ] Follow required checks/review to terminal state.
- [ ] Cleanup worktree and refresh main workspace.

## Handoff Notes

- Main workspace implementation diff is protected in `stash@{0}` at task start: `legion-port:theme-shell-terminal-migration:theme-migration`.
- `.opencode/plans/*.md` are intentionally excluded from the implementation stash and should not be committed.
- Darwin eval is expected to fail until the existing `modules/dev/playwright.nix` / `programs.nix-ld` incompatibility is fixed separately.
