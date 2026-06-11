# vscode-keyring-libsecret

## Metadata

- `task-id`: `vscode-keyring-libsecret`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `2026-06-11`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom's VS Code package now explicitly selects `gnome-libsecret` for password storage.
- The fix addresses Electron's unreliable password-store auto-detection under `XDG_CURRENT_DESKTOP=Hyprland` while continuing to use the existing `gnome-keyring` Secret Service backend.
- The change stays local to `modules/editors/vscode.nix`; Hyprland desktop identity, portals, and keyring service ownership are unchanged.
- Validation passed with axiom top-level eval and dry-run build; live sign-in still requires a post-switch VS Code restart.

## Reusable Decisions

- For VS Code credential storage on Axiom Hyprland, prefer app-level `--password-store=gnome-libsecret` over weaker encryption or global desktop environment spoofing.
- Keep VS Code extension/package wrapping declarative through the existing `vscode-with-extensions` path.

## Related Raw Sources

- `plan`: `.legion/tasks/vscode-keyring-libsecret/plan.md`
- `log`: `.legion/tasks/vscode-keyring-libsecret/log.md`
- `tasks`: `.legion/tasks/vscode-keyring-libsecret/tasks.md`
- `test-report`: `.legion/tasks/vscode-keyring-libsecret/docs/test-report.md`
- `review`: `.legion/tasks/vscode-keyring-libsecret/docs/review-change.md`
- `report`: `.legion/tasks/vscode-keyring-libsecret/docs/report-walkthrough.md`
- `pr`: `.legion/tasks/vscode-keyring-libsecret/pr-url.txt`

## Notes

- Runtime confirmation should happen after `nixos-rebuild switch` or `hey sync switch` on axiom.
- If VS Code/Electron renames accepted password-store choices in the future, revisit the package override rather than broadening the desktop session environment.
