## Summary

- Recover Charlie's RustDesk user LaunchAgent when the first install leaves `com.carriez.RustDesk_server` unloaded in `gui/501`.
- Match the observed IPC metadata (`<c1 uid>:0`, currently `501:0`) instead of c1's primary group (`501:20`) without weakening the existing type, symlink or mode checks.
- Advance the Charlie provision marker from v7 to v8 so prior state cannot be reused as current.

The observed v7 run failed readiness before reservation and before secret resolution/read; it created no ready object or stamp.

## Scope

Production changes are limited to `hosts/charlie/default.nix`. Activation bootstraps the managed user agent only when an active GUI domain exists and the label is missing, then kickstarts it. Secret handling, password-attempt ordering and manual-finalize rules are unchanged.

## Validation

- Generated provision, finalizer and activation syntax/lint/ordering checks: **PASS**.
- Fresh v8 composite revision: `charlie-rustdesk-provision-v4:651ace645ed239c51d10e99c7fa60559bf67a4c9a1ab8495f4d2f7afb8e9be26`.
- Full `aarch64-darwin` build: **PASS**.
- RustDesk 1.4.9 store bundle: **PASS** for arm64, deep/strict codesign, Team ID and Gatekeeper notarization.
- Change review: **PASS**, no blocking findings.

Runtime is **not** PASS. After merge, Charlie still requires a clean merged switch, candidate launchd/IPC observation, destination signature and TCC checks, real authentication positive/negative tests, and manual finalization.

Walkthrough: [`.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md`](.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md)
