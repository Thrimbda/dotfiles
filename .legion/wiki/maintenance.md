# Maintenance

## Nix Evaluation Follow-Up

- Full all-host NixOS evaluation is currently blocked by an unrelated existing package rename: `godot_4-export-templates` should be updated to `godot_4-export-templates-bin` in a separate scoped task if all-host evaluation or full flake checks become required.

## Aliyun Acorn ECS Follow-Up

- Before running live `aliyun-acorn` validation, confirm the OSS bucket/object, image-import RAM role, VPC/vSwitch/security group, instance type, operator SSH CIDR, auto-release time, expected cost/dry-run result, and cleanup owner.
- Run the first live ECS validation by uploading the built QCOW2 to same-region OSS, importing it with `BootMode=UEFI`, creating a temporary validation instance, checking serial console/cloud-init/DHCP/SSH/root partition growth, then cleaning up temporary resources or recording any intentionally retained IDs.
- If `aliyun-acorn` should become a long-lived host, create a follow-up in `~/Work/aliyun-ops` for Terraform-owned ECS/VPC/security-group state instead of preserving one-off CLI state as durable infrastructure.
- After deploying the `aliyun-acorn` Vaultwarden dual-run config, confirm DNS/ACME readiness for `vault.0xc1.space`, then check `vaultwarden.service`, `nginx.service`, `fail2ban.service`, certificate issuance, and `/run/agenix/vaultwarden-env` ownership. Do not split live Vaultwarden traffic between `acorn` and `aliyun-acorn` without a separate data migration/ownership plan.

## Terminal Follow-Up

- Foot terminal notification behavior was disabled by removing unsupported `[main].notify` from the global config. If terminal notification behavior is still desired, restore it only through a Foot 1.25-supported option or an explicit external wrapper design validated with `foot --check-config`.
- After deploying the theme shell/terminal migration, open a fresh shell and tmux session on a host that enables zsh/tmux to confirm the default prompt and `config/tmux/theme.conf` load as expected. Repository-local validation cannot fully prove `~/.config/tmux/theme.conf` post-activation sourcing.
- Split follow-up tasks before moving the remaining `modules/themes` responsibilities: GTK/cursor/fontconfig, wallpapers, Rofi assets, Hyprland visual polish, Doom local theme, and `hey path theme` still need clear owner modules or compatibility boundaries.

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
- After deploying `axiom-steam-dwproton`, run `hey sync --host axiom switch` from a local interactive terminal, restart Steam, and confirm DWProton appears in Steam's compatibility tool selector. Do not claim any specific game compatibility from the repository-only build/eval evidence.
- In a fresh Axiom interactive shell and desktop-launched terminal, confirm `command -v opencode` resolves to `$HOME/.opencode/bin/opencode`.

## Axiom Power Follow-Up

- After deploying `c1ctl-hey-rust-migration`, run `c1ctl status`, switch from an SSH session with `c1ctl mode cli`, confirm the SSH session and remote access services survive, confirm a physically attached display reaches a TTY login, then switch back with `c1ctl mode desktop`. Run `c1ctl reload` from the graphical session to confirm it reaches the existing reload hooks. Smoke the Rust `hey` foundation with `c1ctl path home`, `c1ctl which .backup`, `c1ctl which @rofi wifimenu`, and a safe delegated command such as `c1ctl help sync`. Compare `nvidia-smi --query-gpu=power.draw,pstate,display_active --format=csv` before and after CLI mode before making power-saving claims.
- After deploying `axiom-remove-default-keep-awake`, start a new Hyprland/Caelestia session, confirm `caelestia shell idleInhibitor isEnabled` is not forced back to enabled by Axiom startup hooks, and confirm manual Caelestia Keep Awake toggling still changes that same state. If a previous session persisted Keep Awake enabled, turn it off manually once before judging default idle behavior.
- After deploying `axiom-caelestia-idle-timeouts`, start a new Hyprland/Caelestia session and confirm `~/.config/caelestia/shell.json` has `general.idle.timeouts` set to 900 second `lock` and 1800 second `dpms off` / `dpms on`, with no 600 second sleep action. Confirm Hypridle logs still register 900 second lock and 1800 second DPMS listeners. Do not use automated live suspend or hibernate tests as proof.
- After deploying the Caelestia WlSessionLock switch, start or restart the Hyprland/Caelestia session, run `caelestia shell lock lock`, unlock successfully, then confirm `SUPER+SHIFT+L` and Hypridle's 15 minute listener use the same Caelestia lock surface. Also confirm no `hyprlock` binary or PAM service is present in the generated Axiom system closure.
- After deploying `axiom-remove-never-sleep`, start a new Hyprland/Caelestia session, confirm `caelestia shell idleInhibitor isEnabled` reports enabled, confirm the active Hypridle config/logs show the 15 minute lock and 30 minute DPMS listeners, and confirm no repository-owned sleep-inhibitor user service is active. Do not use an automated live suspend test as proof.
- After deploying `axiom-remove-idle-suspend`, confirm the active Hypridle config/logs show only lock and DPMS listeners, with no automatic suspend listener. Do not use an automated live suspend test as proof.
- After deploying `axiom-hyprland-dpms-safe-mode-fix`, restart the Axiom graphical session, trigger DPMS off/on or suspend/resume, and confirm no new Hyprland coredump, no `Hyprland --safe-mode` restart, and no Caelestia broken-Wayland exit. After a future Hyprland update contains the upstream color-management hotplug fix, remove the Axiom `render.cm_enabled = false` override and repeat the same live smoke.

## Axiom Input Follow-Up

- After deploying the session-owned Caelestia runner, confirm Caelestia Wi-Fi/network and power/session controls no longer report authorization failures. If they still fail, inspect the actual polkit subject classification and `/proc/<caelestia-pid>/cgroup` before widening the allowlist.
- After deploying `axiom-thunar-caelestia-theme-contrast`, open Thunar and confirm file and sidebar labels are readable under `Breeze-Dark` GTK.
- After deploying `axiom-thunar-caelestia-theme-contrast`, restart Fcitx5 or the graphical session, trigger a candidate window, and confirm `FluentDark` has readable contrast while Rime/Pinyin still work.

## Axiom Editor Follow-Up

- After deploying `axiom-vscode-datawrangler-jupyter-extension-fix`, start VSCode from the normal launcher and from `code`, confirm the active extension directory includes `ms-toolsai.datawrangler` and `ms-toolsai.jupyter`, then launch Data Wrangler on a dataframe/notebook and confirm kernel startup no longer reports `Could not get Jupyter extension`. If other VSCode extensions are missing under the managed wrapper, add them to `modules/editors/vscode.nix` explicitly rather than relying on mutable user-installed extensions.

## Axiom Audio Follow-Up

- After deploying `axiom-hdmi-audio-startup-fix`, start a fresh graphical session and confirm `systemctl --user status axiom-hdmi-audio.service easyeffects.service` shows the HDMI readiness unit ran before EasyEffects, `wpctl status` lists `HDA NVidia 数字立体声 (HDMI)` as the default sink, and Zen/Sidra playback reaches the DELL U2720QM headphone output without manual `pactl set-card-profile` toggling.
- After deploying `axiom-audio-pulseaudio-autospawn-fix`, start a fresh graphical session and confirm `pgrep -a pulseaudio` is empty, plain non-session `pactl info` does not autospawn real PulseAudio, desktop `pactl info` reports `PulseAudio (on PipeWire ...)`, and `wpctl status` still lists `HDA NVidia 数字立体声 (HDMI)` as the default sink.

## Axiom Display Follow-Up

- After deploying `axiom-4k240-hdr-display`, restart or reload the Axiom Hyprland session and run `hyprctl monitors` to confirm the active display reports `3840x2160@240`. If the monitor remains at 60Hz, inspect the physical output name, cable/port path, and advertised modes before changing GPU/kernel settings.
- HDR remains a follow-up, not part of the default deployed state. Only remove or relax `render.cm_enabled = false` after the pinned Hyprland package is known to contain the color-management hotplug fix, then repeat a live DPMS/resume smoke before keeping HDR enabled.

## Axiom Virtualization Follow-Up

- After deploying `axiom-win11-kvm-vm`, run `sudo nixos-rebuild test --flake <deployed-dotfiles>#axiom` or switch through the normal host deployment flow, then start a fresh `c1` session and confirm `id c1` includes `kvm` and `libvirtd`, `systemctl is-active libvirtd virtlogd virtlockd` is active, and `virsh -c qemu:///system list --all` works.
- Once libvirt is active, download or provide the Windows 11 ISO, use the repository-provided `virtio-win` media, and create the non-GPU-passthrough Windows 11 VM with Q35, UEFI/Secure Boot capable firmware, swtpm TPM 2.0, VirtIO disk/network, and SPICE display. Verify TPM 2.0, Secure Boot, VirtIO drivers, network, clipboard, and basic desktop responsiveness inside the guest.
- Do not use RTX 5090 passthrough, alter the 1.8T NTFS disk, enable SPICE USB redirection, or bypass Windows licensing/account prompts as part of this follow-up unless a new scoped task explicitly reopens those boundaries.

## Axiom Remote Access Follow-Up

- Delete the mistakenly created `axiom-opencode.0xc1.space` CNAME in Cloudflare DNS/Zero Trust. The active axiom opencode hostname is `opencode-axiom.0xc1.space`.
- Cloudflare Access API verification has configured `opencode-axiom.0xc1.space` and `opencode-charlie.0xc1.space` with Google-only Access apps and exact-email allow policies. `opencode-axiom.0xc1.space` allows `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`, and `wangpeiguangwpg@gmail.com`; `opencode-charlie.0xc1.space` allows `c1@ntnl.io` and `siyuan.arc@gmail.com`. Manual browser smoke checks with allowed accounts and one denied account are still recommended after policy changes.
- After deploying the SSH/opencode/cloudflared fix, run `ssh azar`, `systemctl status autossh-reverse-ssh` on `azar`, and `systemctl status opencode-server cloudflared` on `axiom`.
- After deploying `axiom-cloudflared-http2-transport`, restart or reload `cloudflared.service` on `axiom`, confirm `journalctl -u cloudflared` shows registered `protocol=http2` connections, confirm `https://opencode-axiom.0xc1.space` reaches Cloudflare Access, then stop the temporary user-level HTTP/2 connector if it is still running.
- After deploying the ToDesk service-network fix, run `systemctl status todesk`, launch ToDesk in the graphical session, and confirm the GUI no longer reports no network. Confirm `/var/lib/todesk` is not world-traversable after tmpfiles applies.
- After deploying `axiom-critical-network-resilience`, confirm `systemctl show autossh-reverse-ssh.service cloudflared.service clash-verge.service sshd.service` reports the intended OOM/resource settings, `systemctl list-timers '*healthcheck*'` shows the three healthcheck timers, `curl --fail http://127.0.0.1:20241/ready` passes, the autossh remote endpoint key still matches `axiom`'s local host key, and `systemctl --user show 'app-clash\x2dverge@autostart.service'` reports the GUI drop-in. Then run each healthcheck service once through systemd and inspect journal output before relying on restart automation.
- After deploying `axiom-default-modularization`, confirm `systemctl status opencode-server autossh-reverse-ssh cloudflared gatus` on `axiom`, `systemctl list-timers '*healthcheck*'`, and public Cloudflare Access browser reachability for `opencode-axiom.0xc1.space` and `status-axiom.0xc1.space`.
- After deploying `axiom-host-script-extraction`, confirm `systemctl status todesk`, `systemctl list-timers '*healthcheck*'`, `systemctl --user status axiom-hdmi-audio.service easyeffects.service`, `wpctl status`, and `virsh -c qemu:///system list --all`. Also restart `caelestia-session` and confirm `~/.config/caelestia/shell.json` preserves unrelated user settings while containing the Axiom idle defaults and `bytedance-feishu` favourite without the legacy `.desktop` ID.
- After deploying `axiom-host-policy-extraction`, confirm `systemctl show sshd.service cloudflared.service clash-verge.service 'user@1000.service' -p OOMScoreAdjust -p MemoryMin -p MemoryLow -p Restart -p RestartSec`, `systemctl --user show 'app-clash\x2dverge@autostart.service' -p OOMScoreAdjust -p MemoryLow -p Restart`, `systemctl status gatus cloudflared clash-verge`, `systemctl list-timers '*healthcheck*'`, `nmcli connection show enp14s0`, and that TCP ports `5173,8765` are reachable only from `192.168.50.0/24`.

## Axiom Config Architecture Follow-Up

- `modules/desktop/hyprland.nix` still contains broader Axiom-flavored desktop policy. Split a future desktop/keybinding cleanup if those rules should become host-owned facts or generic module options; do not mix that larger desktop rewrite into service/host modularization tasks.

## Cloudflare Credentials Follow-Up

- Rotate the Cloudflare API token stored in `hosts/charlie/secrets/cloudflare-api-token.age`, because the pre-existing token appeared in earlier tool output before being moved into age management. The user explicitly declined rotation during `axiom-charlie-opencode-access-google-oidc`; keep this as a separate accepted maintenance risk, not as a blocker for the already verified Access app/policy state.

## Status Page Follow-Up

- `status-axiom.0xc1.space` has a verified Cloudflare Access app and proxied CNAME to `home-axiom`; after merging/deploying `gatus-axiom-cloudflare-access`, deploy `axiom` and confirm `systemctl status gatus cloudflared prometheus`, allowed/denied Google Access login behavior, and Prometheus scrape visibility.
- Remove, relocate, or age-encrypt the local plaintext `/home/c1/dotfiles/API_TOKEN.env` after Cloudflare reconciliation; do not commit it.
- Fix the baseline `nix flake check --no-build` app schema failure in unchanged `apps.install = mkApp ./install.zsh` / `lib/nixos.nix` if full-flake checking is required as a merge gate for future tasks.
