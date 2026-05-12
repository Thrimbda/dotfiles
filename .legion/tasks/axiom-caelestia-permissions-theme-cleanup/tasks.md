# Tasks

## Status

- Current phase: PR opened; awaiting merge/review terminal state.
- Branch: `legion/axiom-caelestia-permissions-theme-cleanup-perms-theme`
- Worktree: `.worktrees/axiom-caelestia-permissions-theme-cleanup`
- PR: `https://github.com/Thrimbda/dotfiles/pull/42`

## Checklist

- [x] Create stable task contract.
- [x] Write task-local RFC for polkit/logind/NetworkManager authorization and Catppuccin cleanup.
- [x] Review RFC before implementation.
- [x] Implement minimal Axiom-scoped configuration changes.
- [x] Verify evaluated settings and build surface.
- [x] Review implementation readiness after local-subject fix.
- [x] Produce walkthrough and PR-ready summary.
- [x] Update Legion wiki with current decisions/patterns.
- [x] Commit and push PR branch.
- [x] Open pull request.
- [ ] Reach PR terminal state, then clean up worktree and refresh main workspace.

## Acceptance Tracking

- [x] Caelestia/Quickshell remains managed by `caelestia-shell.service`.
- [x] Desktop shell has the intended local authorization for Wi-Fi/network and power/session actions.
- [x] Axiom file explorer icon theme no longer depends on Catppuccin.
- [x] Axiom Fcitx5 no longer forces the Catppuccin classic UI theme.
- [x] NetworkManager+iwd and Fcitx5 Rime/Pinyin behavior remain unchanged.
- [x] Static validation and live-session follow-up notes are recorded.
