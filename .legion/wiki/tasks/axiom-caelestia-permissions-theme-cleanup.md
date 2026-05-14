# Axiom Caelestia Permissions And Theme Cleanup

## Metadata

- `task-id`: `axiom-caelestia-permissions-theme-cleanup`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-fcitx5-shell-theme-alignment` visual-theme decision for current Axiom Caelestia setup
- `superseded-by`: `axiom-thunar-caelestia-theme-contrast` for the visual-theme conclusion only

## Outcome Summary

This task fixes Axiom Caelestia/Quickshell desktop control authorization and removes the current Catppuccin/Caelestia visible theme mismatch.

The active shell remains Caelestia Shell running through `caelestia-shell.service` and Quickshell `--no-duplicate`. Instead of adding sudo wrappers or restoring old Quickshell config, Axiom now uses a local-primary-user polkit allowlist for selected NetworkManager Wi-Fi/profile actions and selected logind power actions. The final policy requires `subject.local == true`, the primary user, and literal action maps; it does not add `c1` to the broad `networkmanager` group and does not grant `NetworkManager.*` or `login1.*` prefixes.

The theme cleanup disables the Axiom Fcitx5 Catppuccin classic UI override, preserves Rime/Pinyin, replaces the Autumnal icon package with ordinary `papirus-icon-theme`, and replaces the Catppuccin cursor with `Bibata-Modern-Classic` from `bibata-cursors`.

Static validation passed for targeted Axiom config assertions, `git diff --check`, and the Axiom NixOS toplevel build. Live Wi-Fi/power actions and visual checks remain post-deploy smoke tests.

## Reusable Decisions

- For service-owned Caelestia/Quickshell controls on Axiom, treat failures to reboot or control Wi-Fi as polkit subject/authorization issues first, not Unix file permission issues in Quickshell.
- Prefer Axiom-local, local-subject, primary-user, fixed-action polkit allowlists over sudo wrappers, broad `networkmanager` group membership, or prefix grants.
- Historical visual-theme note: this task's categorical Catppuccin-avoidance conclusion is superseded by `axiom-thunar-caelestia-theme-contrast`; current Axiom theme direction is BreezeDark GTK/Qt alignment plus `FluentDark` Fcitx.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/tasks.md`
- `rfc`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-caelestia-permissions-theme-cleanup/docs/pr-body.md`

## Notes

- After deployment, confirm the Caelestia service process is classified as local by polkit. If not, do not widen policy blindly; first capture the exact subject classification.
- After deployment, test Wi-Fi/network control, power/session UI, Thunar icons, and Fcitx5 candidate UI in the real Axiom graphical session.
- For current Thunar/Fcitx visual guidance, use `axiom-thunar-caelestia-theme-contrast` instead of this task's older Catppuccin-avoidance note.
