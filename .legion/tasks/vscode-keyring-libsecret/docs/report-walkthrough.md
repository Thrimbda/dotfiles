# Report Walkthrough

Mode: implementation

## What Changed

- `modules/editors/vscode.nix` now builds VS Code from a local `pkgs.vscode.override`.
- The override passes `--password-store=gnome-libsecret` into VS Code's `commandLineArgs`.
- The existing `vscode-with-extensions` setup still wraps the FHS package and keeps the Jupyter/Data Wrangler extension set unchanged.

## Why

axiom already runs `gnome-keyring` and exposes `org.freedesktop.secrets`, but VS Code/Electron can fail to identify a secure password store when `XDG_CURRENT_DESKTOP=Hyprland`. Explicitly selecting `gnome-libsecret` makes VS Code use the intended Secret Service backend without weakening encryption or spoofing the whole desktop environment.

## Evidence

- `docs/test-report.md`: axiom top-level derivation evaluation passed.
- `docs/test-report.md`: axiom top-level dry-run build passed.
- `docs/review-change.md`: PASS; security lens applied for credential storage behavior, no blocking findings.

## Runtime Note

The current machine still needs a NixOS switch and a full VS Code restart before the packaged `code` launcher includes the new argument.
