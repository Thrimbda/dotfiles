# Axiom VSCode Data Wrangler Jupyter Extension Fix Tasks

## Status

- Current stage: wiki writeback complete; PR lifecycle pending.
- Execution mode: default implementation mode, low-risk hotfix path.
- Worktree: `.worktrees/axiom-vscode-datawrangler-jupyter-extension-fix/`
- Branch: `legion/axiom-vscode-datawrangler-jupyter-extension-fix`
- Base ref: `origin/master`

## Checklist

- [x] Confirm persistent dotfiles/Nix fix boundary with the user.
- [x] Materialize narrow VSCode Data Wrangler/Jupyter extension contract.
- [x] Create isolated worktree from `origin/master`.
- [x] Inspect VSCode/Nix extension packaging conventions.
- [x] Patch the minimal persistent VSCode extension declaration.
- [x] Run targeted Nix validation and record a test report.
- [x] Run readiness review.
- [x] Generate walkthrough/PR body.
- [x] Write Legion wiki updates.
- [ ] Commit, push, open PR, and follow PR lifecycle if requested/available.
- [ ] Cleanup worktree and refresh main workspace after terminal state.

## Handoff Notes

- Reported live error: `Failed to launch kernel. Error: Could not get Jupyter extension` from `ms-toolsai.datawrangler-1.24.1/out/extension.js`.
- Current repository observation: `modules/editors/vscode.nix` installs `vscode.fhs` but does not declare Jupyter/Data Wrangler extension dependencies.
- User selected a persistent dotfiles/Nix fix rather than a one-off local VSCode extension install.
