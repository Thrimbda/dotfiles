# Report Walkthrough

## Mode

Implementation.

## Summary

- Fixed Caelestia launcher-owned GUI app environment by hydrating missing display/session variables from the systemd user manager before launching Caelestia Shell.
- Kept the import narrow and non-invasive: only a fixed allowlist is imported, and only when the variable is currently missing.
- Live smoke validation shows the current Caelestia runner and Quickshell now have `DISPLAY=:0`, and Steam no longer hits the previous `XOpenDisplay failed` path.

## Files Changed

- `modules/desktop/caelestia.nix`: adds display/session environment hydration inside generated `caelestia-session` `session_env()`.
- `.legion/tasks/axiom-caelestia-steam-display-fix/`: records contract, verification, review, and delivery evidence.

## Verification Evidence

- PASS: `git diff --check`.
- PASS: `nix eval --impure --raw '.#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.controlCommand'`.
- PASS: `nix build --impure --print-out-paths --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'`.
- PASS: `bash -n` on generated `/nix/store/nfwivzy55yc02ib1dlclxadr3qs3ywgm-caelestia-session/bin/caelestia-session`.
- PASS: live restart using the generated script, intentionally without `DISPLAY`, resulted in both `caelestia-session` and `quickshell` inheriting `DISPLAY=:0`.
- PASS for scoped Steam display failure: launcher-like `app2unit -- /run/current-system/sw/bin/steam` produced no new `XOpenDisplay failed` / `Unable to open display` entries and progressed into Steam initialization.

## Review Evidence

- Change review verdict: PASS.
- Security lens applied because this changes session environment propagation.
- No blocking findings. The allowlist avoids arbitrary environment import and does not evaluate shell text.

## Residual Notes

- The live smoke launch was scoped to the original display failure. It does not certify Steam account/login/game/runtime behavior.
- A later `Download failed: http error 0` in Steam logs is separate from the X display failure and existed as a pattern before this task.
