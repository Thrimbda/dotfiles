# Maintenance

## Terminal Follow-Up

- Foot terminal notification behavior was disabled by removing unsupported `[main].notify` from the global config. If terminal notification behavior is still desired, restore it only through a Foot 1.25-supported option or an explicit external wrapper design validated with `foot --check-config`.

## Caelestia Shell Follow-Up

- Live Axiom validation remains required inside the actual Hyprland session: start or restart the generated `caelestia-session` runner, confirm the shell process cgroup is under `session-*.scope`, confirm the shell renders, and exercise launcher, sidebar/session/lock, notification/tray, OSD/media/brightness, screenshot/recording, wallpaper, default apps, polkit prompts, NetworkManager, Bluetooth, and power-profile paths.
- If Caelestia global shortcuts or CLI commands differ from the initial static mapping, update the Nix-generated Hyprland keybinds rather than restoring legacy end4 IPC or fuzzel assumptions.
- Revisit local `caelestia/shell.json` only for host policy that must be repository-owned. Avoid copying exhaustive upstream defaults unless a future task proves a stable need.
- After deploying the Caelestia wallpaper Qt theme fix and README alignment, restart Hyprland, confirm `path.txt` points at `/home/c1/.local/state/caelestia/wallpaper/generated.jpg` unless another wallpaper was manually selected, confirm Caelestia logs no longer show the Qt allocation rejection, and verify `qtengine` does not reintroduce launcher color-block icon rendering.
- After deploying `axiom-desktop-polish-followup`, confirm the live Axiom session exercises `Super+Space`, sidebar/session, media, brightness, and screenshot keybinds through the CLI IPC route. If Super-key tap-to-launch is still desired, open a scoped follow-up for safe press/release behavior instead of restoring top-level `catchall`.
- After deploying `axiom-input-caelestia-config-hotfix`, restart `caelestia-session`, confirm `~/.config/caelestia/shell.json` is a writable regular file, exercise `SUPER+Space`, `SUPER+Return`, and workspace bindings, and confirm the keyboard layout `Unknown` toast no longer appears by default. If `hyprctl -j devices` still reports an unknown active keymap, open a separate runtime/upstream input task instead of expanding the config hotfix.
- After deploying `axiom-keybinding-help-modal`, press `SUPER+/` in the real Axiom Hyprland session and confirm the themed shortcut reference modal opens. When generated keybinds change, update the repository-generated help text in the same task.

## Axiom Steam / opencode Follow-Up

- After deploying `axiom-desktop-polish-followup`, confirm Steam renders crisply on the 4K fractional-scale monitor and that games still choose expected render resolutions. If only individual games remain blurry, split a Steam game/runtime task with logs instead of broadening the desktop integration fix.
- In a fresh Axiom interactive shell and desktop-launched terminal, confirm `command -v opencode` resolves to `$HOME/.opencode/bin/opencode`.

## Axiom Power Follow-Up

- After deploying `axiom-keep-awake-nonblocking`, start a new Hyprland session, confirm shell startup is not delayed by Keep Awake waiting, confirm `caelestia shell idleInhibitor isEnabled` reports enabled after Caelestia finishes cold startup, confirm Caelestia's Keep Awake UI shows enabled by default, and confirm toggling the UI changes the same state. If no graphical session starts, this policy is not expected to provide headless/system-wide no-sleep behavior.
- After deploying `axiom-remove-never-sleep`, start a new Hyprland/Caelestia session, confirm `caelestia shell idleInhibitor isEnabled` reports enabled, confirm the active Hypridle config/logs show the 15 minute lock and 30 minute DPMS listeners, and confirm no repository-owned sleep-inhibitor user service is active. Do not use an automated live suspend test as proof.
- After deploying `axiom-remove-idle-suspend`, confirm the active Hypridle config/logs show only lock and DPMS listeners, with no automatic suspend listener. Do not use an automated live suspend test as proof.
- After deploying `axiom-hyprland-dpms-safe-mode-fix`, restart the Axiom graphical session, trigger DPMS off/on or suspend/resume, and confirm no new Hyprland coredump, no `Hyprland --safe-mode` restart, and no Caelestia broken-Wayland exit. After a future Hyprland update contains the upstream color-management hotplug fix, remove the Axiom `render.cm_enabled = false` override and repeat the same live smoke.

## Axiom Input Follow-Up

- After deploying the session-owned Caelestia runner, confirm Caelestia Wi-Fi/network and power/session controls no longer report authorization failures. If they still fail, inspect the actual polkit subject classification and `/proc/<caelestia-pid>/cgroup` before widening the allowlist.
- After deploying `axiom-thunar-caelestia-theme-contrast`, open Thunar and confirm file and sidebar labels are readable under `Breeze-Dark` GTK.
- After deploying `axiom-thunar-caelestia-theme-contrast`, restart Fcitx5 or the graphical session, trigger a candidate window, and confirm `FluentDark` has readable contrast while Rime/Pinyin still work.

## Axiom Remote Access Follow-Up

- Delete the mistakenly created `axiom-opencode.0xc1.space` CNAME in Cloudflare DNS/Zero Trust. The active axiom opencode hostname is `opencode-axiom.0xc1.space`.
- Cloudflare Access API verification has configured `opencode-axiom.0xc1.space` and `opencode-charlie.0xc1.space` with Google-only Access apps and exact-email allow policies. `opencode-axiom.0xc1.space` allows `c1@ntnl.io`, `siyuan.arc@gmail.com`, and `froggy2818@gmail.com`; `opencode-charlie.0xc1.space` allows `c1@ntnl.io` and `siyuan.arc@gmail.com`. Manual browser smoke checks with allowed accounts and one denied account are still recommended after deployment.
- After deploying the SSH/opencode/cloudflared fix, run `ssh azar`, `systemctl status autossh-reverse-ssh` on `azar`, and `systemctl status opencode-server cloudflared` on `axiom`.
- After deploying `axiom-cloudflared-http2-transport`, restart or reload `cloudflared.service` on `axiom`, confirm `journalctl -u cloudflared` shows registered `protocol=http2` connections, confirm `https://opencode-axiom.0xc1.space` reaches Cloudflare Access, then stop the temporary user-level HTTP/2 connector if it is still running.
- After deploying the ToDesk service-network fix, run `systemctl status todesk`, launch ToDesk in the graphical session, and confirm the GUI no longer reports no network. Confirm `/var/lib/todesk` is not world-traversable after tmpfiles applies.

## Cloudflare Credentials Follow-Up

- Rotate the Cloudflare API token stored in `hosts/charlie/secrets/cloudflare-api-token.age`, because the pre-existing token appeared in earlier tool output before being moved into age management. The user explicitly declined rotation during `axiom-charlie-opencode-access-google-oidc`; keep this as a separate accepted maintenance risk, not as a blocker for the already verified Access app/policy state.

## Status Page Follow-Up

- After deploying `gatus-status-page-blackbox-monitoring`, confirm DNS for `status.0xc1.space` points to `acorn`, ACME issuance succeeds, `https://status.0xc1.space` loads, and Prometheus can scrape `http://127.0.0.1:8080/metrics` with Gatus metrics visible.
- Fix the baseline `nix flake check --no-build` app schema failure in unchanged `apps.install = mkApp ./install.zsh` / `lib/nixos.nix` if full-flake checking is required as a merge gate for future tasks.
