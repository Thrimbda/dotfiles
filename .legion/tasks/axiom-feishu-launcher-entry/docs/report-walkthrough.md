# Report Walkthrough

Mode: implementation

## What Changed

- Added `bytedance-feishu.desktop` to Axiom's Caelestia `launcher.favouriteApps` setting.
- Added an Axiom-only `caelestia-shell.service` pre-start script that appends `bytedance-feishu.desktop` to an existing mutable `~/.config/caelestia/shell.json` when missing.
- Kept the existing `feishu` package installation intact.

## Why

`Super+Space` opens the Caelestia launcher, not a raw package list. Installing Feishu adds the package and upstream desktop entry, but does not guarantee it appears in the launcher's default visible menu. The launcher uses desktop ids such as `bytedance-feishu.desktop` for favourites.

## Scope Boundaries

- Only `axiom` is changed.
- No global Caelestia module behavior is changed.
- No duplicate Feishu desktop entry is added.
- No Feishu account, cache, proxy, autostart, credential, or organization-policy state is managed.

## Verification Evidence

- `docs/test-report.md` records PASS for the Caelestia favourite setting: `["bytedance-feishu.desktop"]`.
- `docs/test-report.md` records PASS for `caelestia-shell.service` `ExecStartPre` including `axiom-ensure-feishu-launcher-favorite`.
- `docs/test-report.md` records PASS for `feishu` remaining in Axiom user packages.
- `docs/test-report.md` records PASS for Axiom toplevel evaluation, updater script build plus `bash -n`, and `git diff --check`.

## Review Evidence

- `docs/review-change.md` verdict: PASS.
- No blocking findings.
- Security review found no privileged path, secret, auth, trust-boundary, or user-controlled shell execution issue.

## Residual Risk

Live `Super+Space` rendering and actual Feishu launch still require a post-deploy smoke test in the real Axiom Wayland session.
