# Fix VS Code keyring on axiom

## 目标

Make VS Code sign-in on axiom use the existing GNOME Secret Service keyring instead of falling back to the OS-keyring-identification warning.

## 问题陈述

VS Code shows an OS keyring could not be identified warning when signing in from the axiom Hyprland session, even though gnome-keyring is enabled and org.freedesktop.secrets is available on the user bus. Electron auto-detection is unreliable for Hyprland, so VS Code needs an explicit password store selection.

## 验收标准

- [ ] VS Code launched from the packaged code entry uses gnome-libsecret for credential storage.
- [ ] The fix does not change global Hyprland desktop identity or portal behavior.
- [ ] axiom NixOS configuration evaluates and dry-runs successfully.
- [ ] Legion verification, review, walkthrough, and wiki evidence are recorded.

## 假设 / 约束 / 风险

- **假设**: axiom continues to enable modules.services.gnome-keyring.
- **假设**: The existing gnome-keyring Secret Service registration is the intended secure backend.
- **假设**: VS Code is installed through modules.editors.vscode.
- **约束**: Keep the change minimal and scoped to the VS Code module.
- **约束**: Do not use weaker encryption or disable keyring use.
- **约束**: Do not alter unrelated desktop/session variables.
- **风险**: Future VS Code or Electron versions may rename password-store choices.
- **风险**: The running system still needs a NixOS switch and VS Code restart before the fix is visible.

## 要点

- Prefer explicit VS Code password-store configuration over global XDG_CURRENT_DESKTOP spoofing.
- Reuse nixpkgs vscode commandLineArgs so terminal and desktop entry launches inherit the same behavior.

## 范围

- Update modules/editors/vscode.nix to pass --password-store=gnome-libsecret.
- Validate axiom evaluation and dry-run build.
- Document runtime diagnosis and delivery evidence in Legion.

## 设计索引 (Design Index)

> **Design Source of Truth**: Design-lite: local package override in modules/editors/vscode.nix; no RFC required.

**摘要**:
- Use pkgs.vscode.override commandLineArgs to force gnome-libsecret.
- Continue wrapping the FHS VS Code package with existing Jupyter/Data Wrangler extensions.
- Avoid changing Hyprland XDG_CURRENT_DESKTOP or system-wide Electron defaults.

## 阶段概览

1. **Engineer** - Apply the VS Code package override in the Legion worktree
2. **Verify** - Run axiom Nix evaluation and dry-run build
3. **Review** - Review the change for scope, regressions, and security implications
4. **Report** - Write walkthrough and wiki evidence
5. **Git Delivery** - Commit, push, open PR, and follow lifecycle

---

*创建于: 2026-06-11 | 最后更新: 2026-06-11*
