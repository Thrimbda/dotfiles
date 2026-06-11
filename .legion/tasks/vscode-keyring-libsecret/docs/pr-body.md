## Summary

- Force VS Code to use `gnome-libsecret` for credential storage on axiom/Hyprland.
- Keep the fix scoped to `modules/editors/vscode.nix`; no global desktop identity or portal changes.
- Preserve the existing FHS VS Code wrapper and bundled Jupyter/Data Wrangler extensions.

## Verification

- `nix eval .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath --raw`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`

## Legion Evidence

- Task: `.legion/tasks/vscode-keyring-libsecret/plan.md`
- Test report: `.legion/tasks/vscode-keyring-libsecret/docs/test-report.md`
- Review: `.legion/tasks/vscode-keyring-libsecret/docs/review-change.md`
- Walkthrough: `.legion/tasks/vscode-keyring-libsecret/docs/report-walkthrough.md`

## Runtime Note

After merge/deploy, run a NixOS switch on axiom and restart VS Code. Do not choose weaker encryption in the VS Code prompt.
