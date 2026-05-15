# SSH Foot Term Compatibility Log

## 2026-05-15

- User reported SSH sessions from Foot produce remote Nix `set-environment` errors because the remote cannot find terminal definition `foot`.
- Initial investigation found Foot is configured as the host default terminal and `modules/desktop/term/foot.nix` forces local tmux `default-terminal` to `foot`.
- Found an existing compatibility precedent in `modules/desktop/term/st.nix`, where terminal-specific terminfo is avoided for remote portability.
- The orchestrator mistakenly applied a preliminary fix in the main workspace before using `git-worktree-pr`; user asked to correct this and proceed through the worktree/PR lifecycle.
- Fetched `origin`, created `.worktrees/ssh-foot-term-compat/` from `origin/master`, and opened branch `legion/ssh-foot-term-compat`.
- Materialized a low-risk hotfix contract: keep local Foot behavior, set a portable terminal type at the wrapped SSH boundary, and avoid requiring remote hosts to install Foot terminfo.
- Patched `modules/xdg.nix` so the repository-managed `ssh` wrapper sets `TERM=xterm-256color` before launching SSH, with a short comment explaining the Foot terminfo portability boundary.
- Recorded `docs/test-report.md`. `git diff --check` passed; Axiom and Azar both evaluate `modules.xdg.ssh.enable = true`; the generated Axiom `ssh` wrapper contains `export TERM='xterm-256color'`; the generated `scp` wrapper has no TERM override.
- Change review PASS with no blockers. Security lens was applied because the patch touches SSH; the review found no auth, identity, host-key, permission, secret, crypto, or trust-boundary policy change beyond the terminal type environment value.
- Generated reviewer walkthrough and PR body: `docs/report-walkthrough.md`, `docs/pr-body.md`.
- Completed Legion wiki writeback with task summary and an updated XDG SSH wrapper validation pattern for Foot terminfo portability.
