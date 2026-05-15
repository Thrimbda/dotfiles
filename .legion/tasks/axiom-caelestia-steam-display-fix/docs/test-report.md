# Test Report

## Summary

PASS. The repository change builds, the generated `caelestia-session` script contains the narrow display-variable hydration path, and the live Caelestia shell now receives `DISPLAY=:0`. A Steam smoke launch no longer produced the prior `XOpenDisplay failed` / `Unable to open display` failure and progressed into normal Steam initialization.

## Commands

| Check | Command | Result | Evidence |
|---|---|---|---|
| Diff hygiene | `git diff --check` | PASS | No output. |
| Generated control command eval | `nix eval --impure --raw '.#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.controlCommand'` | PASS | Evaluated `/nix/store/nfwivzy55yc02ib1dlclxadr3qs3ywgm-caelestia-session/bin/caelestia-session`. |
| Axiom toplevel build | `nix build --impure --print-out-paths --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'` | PASS | Built `/nix/store/g6ax1mr7z2vpy47ybnzvi37x3yc6fmj8-nixos-system-axiom-25.11.20260203.e576e3c`. Evaluation emitted existing warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, and renamed options, but the build completed. |
| Generated script syntax | `bash -n /nix/store/nfwivzy55yc02ib1dlclxadr3qs3ywgm-caelestia-session/bin/caelestia-session` | PASS | No output. |
| Generated script content | `Read /nix/store/nfwivzy55yc02ib1dlclxadr3qs3ywgm-caelestia-session/bin/caelestia-session` | PASS | Lines 16-26 show `systemctl --user show-environment` feeding an allowlist: `DISPLAY`, `WAYLAND_DISPLAY`, `XAUTHORITY`, `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP`, `XDG_SESSION_TYPE`, and `HYPRLAND_INSTANCE_SIGNATURE`; each variable is exported only when currently missing. |
| Live Caelestia restart | `env -u DISPLAY ... /nix/store/nfwivzy55yc02ib1dlclxadr3qs3ywgm-caelestia-session/bin/caelestia-session restart` | PASS | The command intentionally omitted `DISPLAY`; restarted `caelestia-session` pid `66183` and `quickshell` pid `66187` both include `DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-1`, `XDG_SESSION_DESKTOP=Hyprland`, `XDG_SESSION_TYPE=wayland`, and the active Hyprland signature. |
| XWayland connectivity | `DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 xrandr --query` | PASS | Returned the active `DP-5` XWayland screen modes. |
| Steam smoke launch | `app2unit -- /run/current-system/sw/bin/steam` with launcher-like session env | PASS for display failure | The command exceeded the shell timeout because Steam remained foregrounded, but the new Steam log section at lines 5036-5200 contains no new `XOpenDisplay failed` or `Unable to open display`. It reached `Create window`, `XRRGetOutputInfo`, GPU topology, desktop state, and runtime launch service startup. |

## Notes

- The post-fix Steam log has a later `Download failed: http error 0` entry at line 5193 after the original display failure was cleared. Similar HTTP update failures existed before this task and are outside the confirmed launcher `DISPLAY` scope unless they become the next user-visible blocker.
- The smoke launch was not used as proof of account/login/game/runtime correctness; it only proves Steam progressed beyond the original X display connection failure.
