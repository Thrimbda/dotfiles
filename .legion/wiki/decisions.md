# Decisions

## Aliyun ECS Image Deployment

`hosts/acorn` dotfiles ownership stops at the NixOS host/image target and guarded ECS custom-image runbook. Durable Aliyun ECS/VPC/security-group state should live in `~/Work/aliyun-ops` Terraform if `acorn` becomes long-lived; dotfiles must not store Aliyun credentials, CLI profiles, Terraform state, `tfvars`, QCOW2 artifacts, private keys, passwords, or account exports.

Imported Alibaba Cloud ECS custom images for `acorn` must set `BootMode=UEFI`, `Architecture=x86_64`, `OSType=linux`, and `Format=qcow2` to match the EFI/systemd-boot NixOS image target. Do not rely on ECS `ImportImage` defaults, because BIOS is the unsafe default for this host shape.

Live Aliyun writes for `acorn` remain gated until bucket, same-region OSS object, image-import role, VPC/vSwitch/security group, instance type, SSH source CIDR, cost/dry-run result, and cleanup policy are confirmed. First-boot SSH access should be injected at runtime through cloud-init `UserData` from local public-key material, not committed authorized keys or passwords.

On `acorn`, Nix binary substitutions should prefer domestic mirrors in this order before existing Cachix and official cache fallback: TUNA `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store`, USTC `https://mirrors.ustc.edu.cn/nix-channels/store`, then SJTU `https://mirror.sjtu.edu.cn/nix-channels/store`. The official `cache.nixos.org` fallback and trusted public key remain part of the final evaluated config. This is a host-local Alibaba Cloud network optimization and does not change global flake inputs or GitHub fetch behavior.

`acorn` NixOS firewall allows TCP `2222` as a host-local port opening. This does not by itself configure the Aliyun security group, start a service on that port, or change SSH authentication/listening behavior.

`acorn` Vaultwarden staging is scoped to `vault.0xc1.wang` only. Do not add `vault.0xc1.space` as an `acorn` compatibility vhost; DNS/ACME readiness and Vaultwarden data ownership must be handled before sending real traffic to this host.

For agenix-backed service migration between hosts, the target host must receive a secret encrypted to its own declared recipient. Do not copy an existing `.age` artifact across hosts unless target-key decryptability is verified; re-encrypt from a valid source decrypt identity directly into the target host's `secrets/` rule context.

`acorn` is a low-resource public server target, not a development or desktop machine. Keep its host profile limited to explicit server role dependencies; do not enable development runtimes, desktop/media tooling, Docker, or host `nix-ld` unless a scoped task proves they are required.

`vault.0xc1.wang` should use Cloudflare-proxied DNS for browser-facing HTTPS and Cloudflare DNS-01 ACME for the `acorn` origin certificate. `status-axiom.0xc1.wang` should also use Cloudflare DNS-01 ACME with DNS-only `A` record origin routing and nginx Basic Auth. Public `80` remains closed; do not use HTTP-01 for this host.

## Linux Workstation Desktop Baseline

Shell prompt and tmux theme defaults are no longer owned by active theme modules. The current default prompt lives in `config/zsh/prompt.zsh` and is sourced by `config/zsh/.zshrc`; the current tmux theme lives in `config/tmux/theme.conf` and is sourced by `config/tmux/tmux.conf`. Do not reintroduce theme-module zsh/tmux injection unless a future scoped task designs an explicit shell theme option.

Terminal font defaults are owned by `modules.desktop.term.font`, and runtime scripts should read `hey.info.term.font`. Do not add new consumers of `modules.theme.fonts.terminal`; that option was removed when shell/terminal ownership moved out of `modules/themes`.

Current Axiom Linux workstation desktop direction is Hyprland + UWSM + NixOS-owned desktop integration, with Zen as the browser baseline, mpv as the scoped media player, Vesktop/Discord as the scoped chat app, Steam Gamescope/Gamemode/Umu tuning, NetworkManager+iwd+resolved for workstation Wi-Fi, and BlueZ/Blueman reliability settings.

Caelestia Shell supersedes the previous repository-managed end4 `ii` desktop direction for Axiom. The active product shell is now the upstream Caelestia shell package with CLI support, integrated by a local NixOS module, while NixOS keeps ownership of UWSM/greetd/portal startup, Hyprland host facts, session-owned shell runner wiring, generated XDG config, rollback, and Darwin isolation.

Axiom must use the upstream `caelestia-dots/shell` flake package output `packages.<system>.with-cli` for the desktop shell. Do not run Caelestia's mutable setup flow, clone live shell source under `~/.config`, or preserve end4 as a fallback product path unless a future task explicitly reopens that architecture.

The active shell lifecycle is the generated `caelestia-session` runner started by the Hyprland startup hook after `hyprland-session.target` environment import. The runner launches `${caelestiaPackage}/bin/caelestia-shell --no-duplicate` from the graphical login session, keeps restart/stop behind the generated control command, and runs repository-owned pre-start migrations before launch. Repository-owned Caelestia shell defaults should stay minimal and seed a mutable user `~/.config/caelestia/shell.json`; exhaustive upstream defaults should be left to upstream, and Home Manager should not continuously own `shell.json` as an immutable Nix-store file.

On Axiom, Caelestia owns wallpaper for the Caelestia desktop session. Do not run the old Hyprland `swaybg` wallpaper hook when `modules.desktop.caelestia.wallpaper.enable` is true. Seed Caelestia's mutable wallpaper state from the `caelestia-session` pre-start path; do not manage `~/.local/state/caelestia/wallpaper/path.txt` as an immutable home-manager file. If the canonical wallpaper source exceeds Qt image decode limits, point Caelestia at a generated decode-safe derivative while preserving the canonical host source.

For the current Axiom Caelestia setup, use upstream README-aligned `QT_QPA_PLATFORMTHEME=qtengine` in the repo-owned Hyprland/UWSM/session runner/session environment and wire the locked `kossLAN/qtengine` flake module. The earlier `qt6ct` launcher icon workaround for upstream `caelestia-dots/shell#1282` is superseded for this new-machine configuration; restore it only through a future scoped live-regression task if the color-block symptom returns.

`caelestia-session` must run with duplicate-instance protection and a PATH that can execute launcher/runtime helpers. Keep shell stop/restart paths behind the generated `caelestia-session` control command; do not bind Hyprland directly to `${caelestiaShell}` because unmanaged quickshell instances can duplicate layers and global shortcuts.

For Axiom Caelestia/Quickshell controls that need NetworkManager or logind authorization, use an Axiom-local polkit allowlist requiring `subject.local == true`, the primary user, and literal action IDs. Do not add the primary user to the broad `networkmanager` group, do not grant `NetworkManager.*` or `login1.*` prefixes, and do not route these controls through sudo wrappers without a new security review.

Axiom graphical sessions must export a deterministic command PATH from generated `uwsm/env` and import `PATH` into the systemd user manager before starting `hyprland-session.target`. Caelestia Shell remains a launcher/app2unit parent with explicit session runner PATH ownership, and that path must include Caelestia helpers, user packages, and generated system packages so GUI-launched terminals and apps can resolve system-profile commands such as `git`, `gawk`, `steam`, and `steam-run`.

Axiom's `hey hook startup` path depends on the repository-managed Janet JPM tree matching the active Janet package ABI. When the evaluated Janet version or `project.janet` dependency declaration changes, activation should rebuild managed JPM artifacts in a staging tree and promote them only after a smoke succeeds. Do not delete the active JPM runtime before a network-backed rebuild, because boot-time DNS/GitHub failures can otherwise block `hyprland-session.target` and Caelestia startup.

Mutable Axiom Caelestia `shell.json` ownership is now part of `modules.desktop.caelestia`: defaults still stay minimal, but durable migrations for Axiom idle defaults, launcher favourites, legacy favourite removal, and Nix package `XDG_DATA_DIRS` discovery belong in the Caelestia module rather than host-local pre-start scripts.

Caelestia Shell launcher children must also inherit the active display/session variables needed by both Wayland and X11/XWayland clients. The generated `caelestia-session` runner should use the systemd user manager as the post-Hyprland-import source of truth and hydrate only missing allowlisted variables such as `DISPLAY`, `WAYLAND_DISPLAY`, `XAUTHORITY`, desktop/session identifiers, and `HYPRLAND_INSTANCE_SIGNATURE` before starting Quickshell.

Axiom user-installed opencode is exposed through explicit zsh startup and generated UWSM/Hyprland session PATH entries for `$HOME/.opencode/bin`; do not rely on literal host-level `environment.variables.PATH = "$HOME/.opencode/bin:$PATH"` as evidence that interactive shells or GUI-launched commands can resolve opencode.

Wayland desktop hosts using the reusable Fcitx5 module should use Fcitx5's native Wayland frontend by default. Do not force `GTK_IM_MODULE=fcitx` from managed session variables when `waylandFrontend` is enabled and working; GTK should use the Wayland text-input path while Fcitx5 GTK/Qt addons can remain installed.

Axiom VS Code credential storage should use the existing GNOME Secret Service backend explicitly through `--password-store=gnome-libsecret`. Do not choose weaker VS Code encryption and do not spoof the whole Hyprland session as GNOME just to satisfy Electron password-store detection.

Current Axiom Caelestia visual theming aligns GTK with qtengine through KDE `Breeze-Dark`/`breeze-gtk` while qtengine uses `BreezeDark.colors`. For Thunar specifically, the repository must also own GTK3 `gtk.css`/`thunar.css` when stale generated CSS would otherwise force light file-manager surfaces over the dark theme; do not treat GTK theme name alone as proof of live Thunar contrast. Fcitx should use a declarative visible theme package/name; Axiom currently uses `fcitx5-fluent` with `Theme=FluentDark`. Do not treat Catppuccin as categorically forbidden, but only choose it through a scoped theme task that deliberately aligns GTK, Fcitx, and Qt/Caelestia together. Keep Rime/Pinyin engine selection separate from visual theme alignment.

Ordinary Axiom idle/keybind lock paths should use Caelestia's own WlSessionLock through `caelestia shell lock lock`. Do not reinstall `hyprlock` or route normal lock requests through `loginctl lock-session` unless a future scoped task proves the logind integration path is stable and intentionally reopens that boundary.

Axiom desktop power policy treats Caelestia's Keep Awake UI as a manual `idleInhibitor` toggle, not as a default startup state, while Hypridle remains the repository-owned idle timing and DPMS policy surface. The checked-in Hypridle idle policy asks Caelestia WlSessionLock to lock at 15 minutes and turns DPMS off/on at 30 minutes; Caelestia's own `general.idle.timeouts` must be aligned to the same 900 second lock and 1800 second DPMS values so upstream's shorter 180/300 second defaults do not win first. Neither Hypridle nor Caelestia should contain a 600 second automatic sleep, suspend, hibernate, or `suspend-then-hibernate` idle action unless a future scoped task explicitly restores automatic idle suspend. Do not restore default `idleInhibitor enable` startup wiring, `hyprlock`, the custom `axiom-sleep-mode` wrapper, Power Mode launchers, Axiom-only Hypridle overrides, or a repository-owned sleep-inhibitor service unless a future task explicitly requires a separate lock client, a user-facing allow-sleep toggle, default never-sleep behavior, or pre-login/headless no-sleep policy. This policy is graphical-session scoped and does not grant logind `ignore-inhibit` or widen polkit power actions. Startup and idle helpers for this policy should call the evaluated `caelestia`/`caelestia-shell` binaries directly, or otherwise own their command lookup, because the Caelestia Python CLI shells out to `caelestia-shell` by name.

Axiom SSH-only operation uses `c1ctl mode cli`, which persists and isolates `axiom-cli.target`. That target keeps `multi-user.target` as the service base, wants `getty@tty1.service` for local-console fallback, and conflicts with `graphical.target` so greetd/Hyprland stop. Return to desktop mode with `c1ctl mode desktop`, which persists and isolates `graphical.target`. `c1ctl` is the durable Rust control CLI under `packages/c1ctl`: privileged mode switching stays fixed-argv `systemctl`, while the first non-Rofi `hey` migration slice moves `path`, `which`, `help`, direct path dispatch, `.foo`, non-Rofi `@namespace`, `wm`, `host`, `theme`, and `exec` foundation behavior into Rust. High-impact mutating workflows such as `sync`, `gc`, `profile`, `pull`, `swap`, `vars`, and hooks remain delegated to existing Janet `hey` until follow-up parity tasks migrate them. `@rofi` is an exact delegation boundary: Rust must not resolve or execute Rofi scripts directly.

Axiom-specific input facts, monitors, workspaces, app rules, environment, and fallback keybinds remain Nix-generated Hyprland config. Generated keybinds should use canonical uppercase Hyprland modifier tokens such as `SUPER`, `CTRL`, `ALT`, and `SHIFT`. Primary shell bindings should target Caelestia global shortcuts or reviewed Caelestia CLI commands, not legacy `quickshell --config ii`, end4 IPC names, `IllogicalImpulse`, matugen, or fuzzel shell assumptions. On Axiom, workspace 1..10 remain primary-monitor workspaces on `SUPER+1..0`, while workspace 11..20 are second-monitor workspaces on `SUPER+ALT+1..0`; moving windows follows the same split with `SHIFT` added.

The active Axiom shortcut reference entrypoint is the generated Hyprland `SUPER+/` binding. It opens the repository-generated `axiom-keybinding-help` modal and should be kept in sync with generated keybind changes.

Axiom ordinary window mouse controls are generated Hyprland bindings, not Caelestia QML behavior: `SUPER + left mouse drag` moves windows, `SUPER + right mouse drag` resizes windows, and `SUPER+SHIFT + wheel down/up` moves the active window to the next/previous workspace. Keep the wheel direction aligned with Caelestia's existing workspace scroll direction unless a future UX task deliberately changes both.

Current Axiom `SUPER+SHIFT+Return` is a tmux workspace terminal entrypoint, not a plain terminal launcher. It opens the default terminal as `foot -e tmux new-session -A -s main` on the foot-backed Axiom host, while `TERMINAL`, `$terminal`, and task-manager terminal commands remain plain terminal defaults.

When Caelestia global-shortcut dispatch does not work in the live Axiom session, repository-generated keybinds may route through reviewed `caelestia shell ...` IPC commands instead. Do not restore top-level Hyprland `catchall` bindings; if Super-key tap semantics are required again, split a scoped follow-up with parser validation.

Current Axiom `Super+Space` opens the Caelestia launcher drawer. Default-visible app additions should use Quickshell `DesktopEntry.id` values in Caelestia `launcher.favouriteApps`; for top-level files like `share/applications/bytedance-feishu.desktop`, the id is `bytedance-feishu` without the `.desktop` suffix. If the user's mutable `caelestia/shell.json` already exists, repository migrations should append or correct the missing value narrowly and preserve all other user settings. The Caelestia session runner must also expose Nix package desktop-entry data through `XDG_DATA_DIRS`; favourites do not make an app discoverable when Quickshell `DesktopEntries` cannot scan the package's `share/applications` path.

Axiom Steam on fractional-scale Hyprland should treat jagged or low-resolution Steam UI first as an XWayland/HiDPI integration issue: enable XWayland self-scaling for scaled monitor configs and pass Steam an explicit desktop UI scale. Do not expand this into per-game Proton or GPU runtime debugging without live evidence.

Axiom Steam may opt into DWProton through `modules.desktop.apps.steam.dwproton.enable`, which appends the pinned `imaviso/dwproton-flake` package to `programs.steam.extraCompatPackages`. Keep DWProton opt-in per host; do not enable it globally for every Steam host or change Steam runtime, Gamescope, MangoHud, Proton-GE, or per-game launch options without a new scoped task.

Axiom notification center 的第一个实现切片采用 session-local Quickshell panel：使用 `NotificationServer.trackedNotifications` 管理当前会话通知，dock button 负责打开 panel，通知内容不持久化。后续不得在没有 retention、clear、disable 和 privacy policy 的情况下把 notification history 或 clipboard history 落盘。

Axiom Stage 2 search/actions 采用 Quickshell-owned panel，而不是恢复 Rofi/DMS primary path 或导入上游 launcher framework。`APP` dock entry 和 primary launcher binding should open Quickshell search first, while Fuzzel remains installed and directly reachable as fallback. Search providers must execute through fixed verbs, reviewed argv arrays, or repository-owned helper subcommands; user query text must not become shell script.

Axiom clipboard history is now allowed for the Stage 2 search surface because this single-user workstation task explicitly chose function completeness. The allowed shape is bounded user-local persistence with finite entry/size caps, visible clear-history behavior, a Nix-owned disable path, and rollback by clearing state or disabling `modules.desktop.quickshell.search.clipboard.enable`.

Axiom Stage 3 quick controls and OSD use a Quickshell-owned panel plus fixed-verb local helper, not deep DBus/control-center parity. The panel may expose shallow status and common actions for audio, network, Bluetooth, media, brightness, power profiles, session/power, resource status, and basic desktop actions, but external tools (`nm-connection-editor`, `blueman-manager`, `pavucontrol`, `wlogout`, `playerctl`, Fuzzel/direct commands) remain the fallback and full-management path until end4 `ii` replaces the transitional shell.

Axiom monitor-headphone audio should treat the NVIDIA DP/HDMI sink `alsa_output.pci-0000_01_00.1.hdmi-stereo` as the real output source of truth. EasyEffects may remain as optional processing, but graphical-session startup must first create/prefer the real HDMI sink and then let EasyEffects bind to it; do not let the EasyEffects virtual sink become the only available sink for Zen/Sidra browser streams. Axiom uses PipeWire's PulseAudio-compatible server; a real `pulseaudio --start` daemon should not run or autospawn because it can hold `hdmi:0` before PipeWire creates the HDMI sink.

Axiom's desktop virtualization stack is now expressed through `modules.virt.libvirt`, which owns libvirt/QEMU service enablement, swtpm, virt-manager, VM packages, and `kvm`/`libvirtd` group membership. Keep `modules.virt.qemu.enable` semantics unchanged unless a separate cross-host task introduces explicit sub-options. The initial Windows 11 VM shape should be a normal system libvirt VM with Q35, UEFI/Secure Boot capable firmware, emulated TPM 2.0, VirtIO storage/network, SPICE display, and no PCI GPU passthrough.

Axiom OSD feedback should prefer Quickshell IPC for volume/brightness/media display while preserving existing state-changing commands. Volume and brightness continue through `hey .osd` wrappers, and media keys may route through `axiom-control-helper media ...`; if Quickshell IPC is unavailable, notify/direct command fallback must keep the key behavior operational.

Old X11/bspwm/sxhkd/Polybar/Dunst/Waybar/legacy-idle/browser/media/Spotify compatibility is not preserved unless a future task explicitly reopens that scope.

Hyprland display-manager wiring should start through UWSM and resolve to the evaluated `start-hyprland` launcher path. Do not point greetd at `hyprland-uwsm.desktop` when that path reparses to direct `Hyprland`, because Hyprland 0.53 warns that direct startup without `start-hyprland` is only appropriate for debugging.

Hyprland 0.53 active configuration must use the current `windowrule`/`layerrule` syntax. `windowrulev2` is a parse error in the evaluated Hyprland 0.53.3 package, and old layer-rule spellings such as `noanim`, `dimaround`, `ignorezero`, and `ignorealpha` should not be used in active config.

On Axiom, Hyprland 0.53.3 color management is temporarily disabled with `render.cm_enabled = false` because DPMS/suspend resume logs and coredumps show the safe-mode incident originates in Hyprland's `NColorManagement::CImageDescription::id()` hotplug path before Caelestia loses its Wayland connection. Treat this as a local mitigation, not an upstream fix; remove it only after the pinned Hyprland package includes the upstream fix and a live DPMS/resume smoke passes.

Axiom display policy is now dynamic and inventory-driven rather than a single wildcard 4K240 fallback rule. `modules.desktop.hyprland.monitors` is the cohesive source of truth for known monitor identity, layout, fallback mode, native-max-refresh policy, and optional Caelestia per-monitor settings. DP-4 Microstep MPG272UX OLED should fall back to 4K240, DP-5 Dell U2720QM should fall back to 4K60, and unknown hotplug outputs on Axiom should use native/highest-resolution first and the highest refresh at that resolution with auto positioning and scale 1.5. HDR remains lower priority than stable refresh while `render.cm_enabled = false` is still the active DPMS/resume stability mitigation; do not claim Axiom runtime HDR is enabled until color management is deliberately re-enabled and verified in a live session.

Hyprland startup must bootstrap the visible product session before lock-screen or visual hooks can block it. The active startup path is `exec-once = hey hook startup`; the early hook imports compositor environment variables and starts `hyprland-session.target`, while wallpaper remains a later hook. Do not restore foreground `hyprlock --immediate` as a startup gate for DMS/Quickshell or wallpaper; use a real greeter or non-blocking lock flow in a future scoped task if boot-time physical access protection is required.

When NetworkManager uses iwd as the Wi-Fi backend, NetworkManager owns DHCP/routes. iwd's built-in network configuration should stay disabled, and workstation wired DHCP/autoconnect should be modeled through NetworkManager profiles rather than legacy `dhcpcd`. Do not globally set NetworkManager `no-auto-default=*` for workstations unless every required link has a known-good explicit profile, because it can block fallback default connection creation.

## Darwin Boundary

Darwin remains a shared shell/dev/editor/XDG target. Linux desktop/system concerns such as Hyprland, DMS/Quickshell, Steam, NetworkManager/iwd, BlueZ/Blueman, portals, and display-manager wiring must stay out of Darwin imports unless a future Darwin-specific task changes the contract.

## NixOS Package Set Evaluation

NixOS configurations reuse the host package set through `nixpkgs.nixosModules.readOnlyPkgs` plus `nixpkgs.pkgs = hostInfo.pkgs`. Do not pass `pkgs` through NixOS `specialArgs`; that continues to trigger the `specialArgs.pkgs` warning even when `readOnlyPkgs` is imported.

Under read-only pkgs, module `pkgs` is provided through configuration, so import-time platform decisions and top-level config shape should use the plain `hostSystem` special argument. Do not force `pkgs.stdenv.isLinux` or `pkgs.stdenv.isDarwin` in `imports` or top-level `optionalAttrs` / `mkIf` conditions that affect module collection.

When NixOS uses a prebuilt pkgs set, local modules should not set `nixpkgs.overlays` or `nixpkgs.config`. Put durable package-set customization in the flake's package construction path instead, or keep it explicitly Darwin-only if it is only intended for nix-darwin.

## Reverse SSH Tunnels

Current autossh reverse tunnels to `8.159.128.125` bind remote loopback explicitly and forward back to each host's local SSH daemon on `127.0.0.1:22`. For Axiom, the remote host is mutable/reinstallable, but the system service pins the current remote ED25519 key in a service-specific known-hosts file and sets `UserKnownHostsFile=/dev/null` so strict host-key checking does not depend on stale user-level known-hosts state or global `/etc/ssh/ssh_known_hosts` state. Keep endpoint identity checks focused on proving the reverse port reaches the expected local host key.

- `charlie`: remote `127.0.0.1:2222` -> local `127.0.0.1:22` through the Darwin launchd user agent to `c1@8.159.128.125`.
- `axiom`: remote `127.0.0.1:2223` -> local `127.0.0.1:22` through the NixOS systemd service to `c1@8.159.128.125`; `axiom` uses persistent `sshd.service` rather than OpenSSH socket activation so the local tunnel target is daemon-backed.
- `azar`: remote `127.0.0.1:2224` -> local `127.0.0.1:22` through the NixOS systemd service to `root@8.159.128.125`; `azar` uses persistent `sshd.service` rather than OpenSSH socket activation so the local tunnel target is daemon-backed.

Do not reuse an existing remote port while its host tunnel remains active, and do not relax the remote bind address away from `127.0.0.1` without a new security review.

On `axiom`, critical network services are protected as a tiered survival path. `sshd.service` and `autossh-reverse-ssh.service` use `OOMScoreAdjust=-900`; `cloudflared.service` and `clash-verge.service` use `OOMScoreAdjust=-850`; the Clash GUI autostart drop-in normalizes to `OOMScoreAdjust=0` with `MemoryLow=256M`. The system services also use `MemoryMin`/`MemoryLow` and restart policy tuned for recovery.

Those Axiom survival/resource policies are now expressed through owning module options rather than host-level `systemd.services.*` blocks: SSHD through `modules.services.ssh.serviceConfig`, Cloudflared through `modules.services.cloudflared.servicePolicy`, Clash through `modules.desktop.apps.clash-verge.servicePolicy`, Clash GUI autostart through `modules.desktop.apps.clash-verge.guiAutostart`, and the user manager through `modules.profiles.workstation.userManager`.

`axiom` autossh endpoint identity is an on-demand operator diagnostic, not timer-driven automation. The durable check is `c1ctl autossh check`: connect as `c1@8.159.128.125`, scan remote `127.0.0.1:2223`, and compare the exposed ED25519 host key with `axiom`'s `/etc/ssh/ssh_host_ed25519_key.pub`. Stale remote listeners remain manual cleanup unless a future task explicitly designs safe remote cleanup.

## FRP Tunnels

The frp deployment path is additive to autossh. `acorn` owns `frps` on TCP `7000`, and `axiom` owns `frpc` proxy `axiom-ssh` from local `127.0.0.1:22` to remote TCP `2225` on `8.159.128.125`.

For the first `0xc1.wang` public entry slice, `axiom` also owns frp proxy `axiom-gatus-http` from local Gatus `127.0.0.1:8080` to remote TCP `18080` on `acorn`. This remote port is an nginx backend only and must not be opened in the NixOS firewall or Aliyun security group.

For the parallel OpenCode `0xc1.wang` entry, `axiom` owns frp proxy `axiom-opencode-http` from local OpenCode `127.0.0.1:4096` to remote TCP `18081` on `acorn`. This remote port is an nginx backend only and must not be opened in the NixOS firewall or Aliyun security group.

On Axiom, frpc traffic to Acorn must bypass Clash/Meta TUN routing. Axiom owns `frpc-acorn-direct-route.service`, which installs policy rule priority `8500` for `8.159.128.125/32` through the `main` routing table before `frpc.service` starts. Keep this host-local unless another machine shows the same Clash/Meta routing failure.

FRP token auth must use host-local agenix secrets and runtime TOML rendering from `/run/agenix/frp-token`; do not place plaintext token values in Nix TOML, module options, task docs, PR bodies, or Nix store outputs.

The Acorn frps dashboard, when enabled, must bind only to `127.0.0.1:7500` and be exposed through nginx as `frps-acorn.0xc1.wang` behind the Acorn Auth Mini Gateway `auth_request` boundary. TCP `7500` is a loopback dashboard backend and must not be opened in the NixOS firewall or Aliyun security group.

Do not use frp remote TCP `2222`, `2223`, or `2224` for this proxy while the existing autossh reservations for `charlie`, `axiom`, and `azar` remain active.

## Acorn Auth Mini Gateway

`auth-mini` is the Acorn-hosted authentication issuer at `auth.0xc1.wang`. It runs as a loopback-only service on `127.0.0.1:7777` with SQLite state under `/var/lib/auth-mini`; public traffic reaches it only through nginx HTTPS.

`auth-mini` serves the browser UI under `/web/`; nginx should redirect exact `https://auth.0xc1.wang/` to `/web/` so the public root is usable instead of exposing the API fallback `404`.

Cloudflare DNS-only A records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang` point to Acorn at `8.159.128.125`. Treat those DNS records as part of the release artifact for new Acorn public hostnames, not as optional post-deploy cleanup.

`auth-mini-gateway` protects Acorn's human-facing `0xc1.wang` nginx reverse proxies via nginx `auth_request`. Current protected hostnames are `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang`.

Current upstream gateway behavior is same-origin: it validates returns against one `GATEWAY_PUBLIC_BASE_URL` and emits host-only cookies. Therefore Acorn must run one gateway instance per protected hostname instead of one central cross-host callback service. The current loopback allocation is `auth-gateway.0xc1.wang -> 7778`, `status-axiom.0xc1.wang -> 7779`, `opencode-axiom.0xc1.wang -> 7780`, and `frps-acorn.0xc1.wang -> 7781`.

The gateway cookie secret and allowlist live in `hosts/acorn/secrets/auth-mini-gateway-env.age`; do not put gateway secrets, refresh tokens, or plaintext allowlists into Nix store paths, task docs, PR bodies, or logs. Backend ports `7777` through `7781` must remain absent from the public firewall and cloud security group.

`vault.0xc1.wang` remains outside the gateway because Vaultwarden has native clients and app-level authentication. Do not put Vaultwarden behind the browser gateway without a separate compatibility design and native-client smoke plan.

## Opencode Cloudflare Exposure

`axiom` opencode exposure uses a local-only systemd service running `/home/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096`, with cloudflared ingress on `opencode-axiom.0xc1.space`. `charlie` uses the same loopback opencode pattern through `opencode-charlie.0xc1.space`.

On `axiom`, the `opencode-axiom.0xc1.space` cloudflared connector should pin `protocol = "http2"` in host-level `extraConfig` while the current Clash/Meta fake-ip network path causes cloudflared default QUIC/UDP edge dial timeouts. Keep this as a connector transport override in generated `/etc/cloudflared/config.yml`; do not replace it with a temporary user-level connector as durable state.

Both opencode hostnames are protected by Cloudflare Access self-hosted applications restricted to the Google identity provider. Their allow policies require the same Google login method. `opencode-axiom.0xc1.space` allows exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`, and `wangpeiguangwpg@gmail.com`; `opencode-charlie.0xc1.space` allows exact emails `c1@ntnl.io` and `siyuan.arc@gmail.com`. Do not broaden these apps to a domain, group, everyone rule, bypass rule, or non-identity policy without a new security review.

`opencode-axiom.0xc1.wang` is a parallel Acorn/frp route to Axiom OpenCode. It must use the Acorn Auth Mini Gateway at the Acorn origin, because Cloudflare Access on other hostnames does not protect direct origin requests by IP plus Host/SNI. This does not migrate or replace `opencode-axiom.0xc1.space`.

The hostname `axiom-opencode.0xc1.space` was created by mistake during the axiom task and should not be used.

For cloudflared age secrets, Linux hosts should use group `users`; Darwin hosts should keep group `staff`.

## Axiom ToDesk Runtime

On `axiom`, ToDesk is a desktop remote-access integration owned by `modules.services.todesk`. The module installs the package and owns runtime connectivity through a systemd service running `${pkgs.todesk}/bin/todesk service` as `c1` after `network-online.target`.

ToDesk state lives in `/var/lib/todesk` and should be created declaratively with `0700 c1 users`, because the vendor binaries write auth/private state there and both GUI and service run as `c1`. Do not add inbound firewall allowances for ToDesk without a separate scoped security review.

## Clash Verge On NixOS

Clash Verge Rev on NixOS should be integrated through the upstream `programs.clash-verge` NixOS module, not through the GUI's service-mode or TUN installers. Hosts enabling the dotfiles `modules.desktop.apps.clash-verge` module should get declarative service mode, TUN mode, autostart, and package pass-through from NixOS.

For TUN connectivity, the current default trusted interface set is `Mihomo` and `Meta`, paired with a reverse-path filter exception for those names. Do not globally disable reverse-path filtering or migrate to `services.mihomo` unless a future scoped task explicitly chooses that route.

Remote-access endpoints that must remain direct can use host-local policy rules with a priority lower than Clash/Meta rules. The current Axiom example is `8.159.128.125/32 lookup main` at priority `8500` for frpc to Acorn; do not broaden this to general proxy bypass without a scoped review.

For axiom terminal-driven Clash Verge node switching, use the local Clash/Mihomo controller API at `http://127.0.0.1:9090` with default group `Nexitally`. Do not edit subscription YAML or proxy-group definitions for runtime node switching. If a controller secret is configured, pass it at runtime and keep it out of repository files.

## Status Page And Black-Box Monitoring

Gatus is the repo-managed status page and black-box monitoring entrypoint for `axiom`, using NixOS-native `modules.services.gatus` with host-local endpoint inventory. It should stay NixOS-native, not Docker Compose, unless a future task explicitly changes deployment style.

Reusable Gatus endpoint inventory should be represented through `modules.services.gatus` helpers: common labels, public endpoint entries, the self status-page endpoint, and optional Cloudflared ingress contribution. Hosts should pass endpoint facts such as name, URL, service label, and public hostname instead of maintaining full endpoint boilerplate.

The public hostname is `status-axiom.0xc1.space` through the existing `home-axiom` cloudflared tunnel to local `127.0.0.1:8080`. Cloudflare Access is the authentication boundary; cloudflared is only transport. Create or modify the public DNS/tunnel route only after the `status-axiom.0xc1.space` Access app/policy has been verified.

The parallel `status-axiom.0xc1.wang` hostname is a DNS-only `acorn` nginx entry backed by frp remote TCP `18080` to the same Axiom Gatus loopback service. It must use the Acorn Auth Mini Gateway at the Acorn origin. This does not migrate or replace `status-axiom.0xc1.space`, and it does not authorize direct nginx exposure for other sensitive services without a scoped gateway-backed design.

Gatus covers user-visible availability, TLS/route checks, status page display, and Prometheus-exported probe results. Prometheus remains the white-box metrics system for application and infrastructure metrics.

The public Gatus page should only include public-safe endpoints. Do not add private database, Redis, message queue, or internal-only dependency hostnames to the public status page without a new security review.

## Axiom Playwright Runtime

When `modules.dev.playwright.enable = true` on Linux, the Playwright dev module should expose Chromium runtime libraries through `programs.nix-ld.libraries`. The Nix-packaged `playwright` wrapper remains the preferred baseline, but npm/npx Playwright downloads Ubuntu fallback browsers on unsupported Linux distributions, so those binaries also need a working `nix-ld` library path.

Because `modules.dev.playwright` is also imported by Darwin hosts, the NixOS-only `programs.nix-ld` definition must only be generated when the module option exists. A platform `mkIf` around an unknown option is not sufficient protection for nix-darwin module checking.
