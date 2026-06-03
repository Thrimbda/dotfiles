# Review Change

## Verdict

- Result: PASS
- Reviewed scope: `modules/editors/vscode.nix` plus Legion task evidence.
- Security lens: no dedicated security review was triggered. The change adds Microsoft VSCode marketplace extensions already required by the reported workflow, but it does not alter auth, secrets, permissions, network trust boundaries, or privileged input handling.

## Blocking Findings

- None.

## Scope Check

- In scope: the VSCode module now persists Data Wrangler, Jupyter, and Jupyter's extension pack members through `vscode-with-extensions`.
- In scope: the wrapper keeps the existing `pkgs.vscode.fhs` editor package as the underlying VSCode package.
- In scope: validation evidence confirms the Axiom host user package selection resolves to `code-with-extensions-1.106.2` and the generated extension directory contains `ms-toolsai.datawrangler/` and `ms-toolsai.jupyter/`.
- Out of scope not touched: Data Wrangler source code, global Python/Jupyter runtime setup, editor defaults, and unrelated development tooling.

## Non-Blocking Notes

- `vscode-with-extensions` sets a generated `--extensions-dir`, so VSCode will use the declarative extension set from this module. This is appropriate for the selected persistent dotfiles fix, but additional manually installed extensions may need to be declared later if the user expects them to be available under the managed wrapper.
- Interactive Data Wrangler launch was not run in this non-interactive session. The available evidence directly proves the extension lookup failure should be addressed because the runtime extension directory contains `ms-toolsai.jupyter/`.

## Evidence Reviewed

- `docs/test-report.md`
- `nix-instantiate --parse modules/editors/vscode.nix`
- Axiom user package evaluation returning `["code-with-extensions-1.106.2"]`
- Successful build of the Axiom VSCode wrapper package
- Generated wrapper script and extension directory inspection
- `git diff --check`
