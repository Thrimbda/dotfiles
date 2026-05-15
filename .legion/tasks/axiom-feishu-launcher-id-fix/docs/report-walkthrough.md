# Report Walkthrough

## Mode

Implementation.

## Summary

- Corrects Axiom's Feishu Caelestia launcher favourite id to `bytedance-feishu`.
- Updates the mutable config migration to replace the legacy incorrect `bytedance-feishu.desktop` value.
- Preserves Feishu package discovery through the upstream desktop file.

## Why

Quickshell scans `share/applications/bytedance-feishu.desktop`, but stores the desktop-entry id as the file basename without the `.desktop` suffix. Caelestia favourites compare against that id, so the favourite must be `bytedance-feishu`.

## Evidence

- Verification: `docs/test-report.md`
- Change review: `docs/review-change.md`

## Live Action

The live `~/.config/caelestia/shell.json` was updated to include `bytedance-feishu`, and the current `caelestia-session` was restarted so the user can immediately recheck `Super+Space`.
