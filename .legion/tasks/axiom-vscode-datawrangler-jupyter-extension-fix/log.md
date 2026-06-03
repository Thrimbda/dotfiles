# Axiom VSCode Data Wrangler Jupyter Extension Fix Log

## 2026-06-02

- Entered Legion via `legion-workflow` because the user explicitly requested a Legion-managed fix.
- Entered `brainstorm` because no existing task id/path was provided.
- Confirmed the repair boundary with the user: persist the fix in dotfiles/Nix rather than only repairing the current local VSCode extension state.
- Materialized the task contract and initial checklist for the persistent VSCode Jupyter extension fix.
- Created worktree `.worktrees/axiom-vscode-datawrangler-jupyter-extension-fix/` on branch `legion/axiom-vscode-datawrangler-jupyter-extension-fix` from `origin/master`.
- Engineer stage: replaced the plain `vscode.fhs` package with a `vscode-with-extensions` wrapper over `pkgs.vscode.fhs`.
- Engineer stage: declared `ms-toolsai.datawrangler`, `ms-toolsai.jupyter`, and the Jupyter extension pack members because the wrapper uses a generated `--extensions-dir` and does not auto-expand `extensionPack` entries.
- Engineer check: `nix-instantiate --parse modules/editors/vscode.nix` passed.
- Engineer check: the edited VSCode wrapper expression evaluated to `code-with-extensions-1.106.2`.
- Verify stage: Axiom user package evaluation returned `["code-with-extensions-1.106.2"]`.
- Verify stage: building the Axiom VSCode wrapper package passed.
- Verify stage: inspected the generated wrapper and extension directory; it includes Data Wrangler, Jupyter, and the Jupyter extension pack members.
- Verify stage: `git diff --check` passed.
- Review stage: readiness review passed with no blocking findings.
- Review note: managed `vscode-with-extensions` extension directories can hide undeclared manual extensions; this is non-blocking for the selected persistent dotfiles fix and documented for follow-up if needed.
- Report stage: generated implementation-mode `docs/report-walkthrough.md` and `docs/pr-body.md` from existing validation and review evidence.
- Wiki stage: added task summary, VSCode declarative extension validation pattern, and Axiom editor post-deploy smoke follow-up.
