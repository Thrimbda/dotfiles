# axiom-vscode-datawrangler-jupyter-extension-fix

## Metadata

- `task-id`: `axiom-vscode-datawrangler-jupyter-extension-fix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-06-02`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's VSCode module now treats Data Wrangler's Jupyter dependency as a repository-managed extension set instead of relying on mutable user-installed extensions.
- The active implementation wraps `pkgs.vscode.fhs` with `pkgs.vscode-with-extensions` and declares `ms-toolsai.datawrangler`, `ms-toolsai.jupyter`, and Jupyter's extension pack members.
- Non-interactive validation proved the Axiom user package list resolves to `code-with-extensions-1.106.2`, the wrapper builds, and the generated extension directory contains Data Wrangler and Jupyter.
- Interactive Data Wrangler launch remains a post-deploy graphical-session smoke check.

## Reusable Decisions

- When `vscode-with-extensions` is used, declare both the primary extension and any `extensionPack` members that must be present in the generated extension directory; do not assume the wrapper expands extension packs automatically.
- Because the wrapper uses a generated `--extensions-dir`, manually installed VSCode extensions may need to be promoted into the declarative extension list if they should remain available.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-vscode-datawrangler-jupyter-extension-fix/plan.md`
- `log`: `.legion/tasks/axiom-vscode-datawrangler-jupyter-extension-fix/log.md`
- `tasks`: `.legion/tasks/axiom-vscode-datawrangler-jupyter-extension-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-vscode-datawrangler-jupyter-extension-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-vscode-datawrangler-jupyter-extension-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-vscode-datawrangler-jupyter-extension-fix/docs/report-walkthrough.md`
