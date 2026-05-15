# Report Walkthrough

## Mode

Implementation.

## Summary

- Fixes the remaining Axiom Feishu launcher gap by exposing package desktop-entry data to `caelestia-shell.service` through `XDG_DATA_DIRS`.
- Keeps the previous `bytedance-feishu.desktop` favourite and mutable `shell.json` updater intact.
- Does not create duplicate desktop entries or touch Feishu runtime/account/proxy/autostart state.

## What Changed

- `hosts/axiom/default.nix` now computes `caelestiaLauncherDataDirs` from the evaluated Axiom user and system package closures with `makeSearchPath "share"`.
- `hosts/axiom/default.nix` sets `systemd.user.services.caelestia-shell.environment.XDG_DATA_DIRS` to that value.
- Task evidence was added under `.legion/tasks/axiom-feishu-launcher-discovery-fix/**`.

## Why

Caelestia's launcher uses Quickshell `DesktopEntries.applications`. Quickshell scans `$XDG_DATA_HOME/applications` and each `$XDG_DATA_DIRS` element with `/applications` appended. Without a Nix-aware `XDG_DATA_DIRS` in the Caelestia shell process, the app database can miss Feishu's package-provided `share/applications/bytedance-feishu.desktop` even when the id is listed as a favourite.

## Evidence

- RFC: `docs/rfc.md`
- RFC review: `docs/review-rfc.md`
- Verification: `docs/test-report.md`
- Change review: `docs/review-change.md`

## Validation Summary

- PASS: `caelestia-shell.service.environment.XDG_DATA_DIRS` contains Feishu's package `share` path.
- PASS: Feishu package contains `share/applications/bytedance-feishu.desktop`.
- PASS: Caelestia favourite config remains `["bytedance-feishu.desktop"]`.
- PASS: Feishu remains in Axiom user packages.
- PASS: Feishu favourite pre-start hook remains configured.
- PASS: Axiom toplevel derivation evaluates.
- PASS: `git diff --check`.

## Residual Risk

Live `Super+Space` rendering and launch still require deployment into the real Axiom Wayland session, followed by a restart of `caelestia-shell.service` or a new Hyprland session.
