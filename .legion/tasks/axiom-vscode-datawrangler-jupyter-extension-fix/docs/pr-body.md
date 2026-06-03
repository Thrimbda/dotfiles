## Summary

- Persist Data Wrangler and Jupyter VSCode extensions in the Axiom VSCode module.
- Keep `pkgs.vscode.fhs` as the underlying editor package while wrapping it with `vscode-with-extensions`.
- Include Jupyter's extension pack members explicitly so the generated extension directory is complete.

## Validation

- `nix-instantiate --parse modules/editors/vscode.nix`
- Axiom user package evaluation returned `["code-with-extensions-1.106.2"]`
- Built the Axiom VSCode wrapper package successfully
- Confirmed the generated extension directory contains Data Wrangler, Jupyter, and Jupyter extension pack members
- `git diff --check`

## Notes

- Interactive VSCode/Data Wrangler launch was not run in this session.
- The managed wrapper uses a generated `--extensions-dir`; additional manual extensions should be declared later if they are expected in the managed VSCode profile.
