# Patterns

## Git Flake Validation With New Files

When validating a Git-backed flake after adding new module files or encrypted secret files, mark those files as tracked or intent-to-add before running `nix eval`/`nix build`. Otherwise Nix may evaluate the Git source without untracked files, and `_module.check = false` can hide missing option declarations or missing path inputs.

Recommended pre-validation command shape:

```sh
git add -N <new-module-files>
```

The final commit must still add the files normally.

When validating an impure flake from a nested PR worktree, set `DOTFILES_HOME` to the worktree path and prefer a `path:` flake reference to that worktree. A stale ambient `DOTFILES_HOME` can cause generated Home Manager sources to point at an older Nix store snapshot even when the command is run from the intended worktree.

## Host-Level Nix Binary Cache Mirror Pattern

For a machine-specific domestic Nix cache preference, add mirrors at the host level with `nix.settings.substituters = lib.mkBefore [ "<mirror>" ... ];` rather than changing global flake inputs or forcing all hosts to use the same mirrors. Keep existing Cachix and `https://cache.nixos.org/` fallback unless the task explicitly scopes an offline or official-cache-blocked environment. For China-hosted Alibaba Cloud machines, the current `aliyun-acorn` order is TUNA, USTC, then SJTU.

Validate mirror changes by evaluating the final host substituter list, trusted public keys, and the most relevant host or image derivation. The substituter-list eval proves merge order and fallback preservation; the trusted-key eval proves official cache trust is still present when relying on official mirrors; the drvPath eval proves the NixOS module/image graph still evaluates. A one-off machine command can temporarily override cache choice with `--option substituters "<mirror-1> <mirror-2> https://cache.nixos.org/"` without landing configuration.

When a task only asks to open a NixOS firewall port, keep the change at `networking.firewall.allowedTCPPorts` for the scoped host and do not infer service listener, authentication, SSH port, or cloud security-group changes without an explicit contract.

## NixOS Read-Only Pkgs Pattern

When a NixOS configuration intentionally reuses an already imported host package set, use the recommended read-only path: include `nixpkgs.nixosModules.readOnlyPkgs`, set `nixpkgs.pkgs = <host pkgs>`, and do not pass `pkgs` through `specialArgs`.

Because `readOnlyPkgs` makes module `pkgs` config-provided rather than externally supplied, avoid `pkgs.stdenv.isLinux` / `pkgs.stdenv.isDarwin` in `imports` and top-level config-shaping expressions. Pass a plain host system string such as `hostSystem` and derive booleans from that string for import-time platform branching.

Validate warning-cleanup changes with a representative host toplevel evaluation and dry-run build. For this repository, `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` plus `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` directly exercises Hyprland, audio, agenix, and desktop platform paths without requiring a privileged switch.

## Aliyun ECS Custom Image Deployment Pattern

For NixOS QCOW2 images intended for Alibaba Cloud ECS custom-image import, validate the repository-owned image target before any cloud writes. At minimum, evaluate the image flake system, run a build dry-run, and prefer `nix build --no-link` for full artifact proof so no `result` symlink or QCOW2 artifact is accidentally added to the repository.

Keep Aliyun credentials and durable cloud state outside dotfiles. Use the approved ops environment, such as `~/Work/aliyun-ops` with local `aliyun configure`, `ossutil`, and Terraform conventions. Do not commit AccessKeys, Aliyun CLI profiles, Terraform state, `tfvars`, local cloud exports, passwords, SSH private keys, or generated QCOW2 images.

For ECS image import, use an OSS object in the same region as `ImportImage`, preflight the image-import RAM role and object visibility, and pass explicit image parameters: `Architecture=x86_64`, `OSType=linux`, `Format=qcow2`, and `BootMode=UEFI` for EFI/systemd-boot NixOS images. Treat Alibaba Cloud defaults as unsafe unless verified against the current image shape.

For first-boot validation, generate cloud-init `UserData` locally from a public SSH key at execution time, run `RunInstances` with `--DryRun true` before live creation, restrict SSH ingress to an operator CIDR, and bound temporary validation instances with auto-release when possible. Validate serial console/system logs, cloud-init, DHCP/networkd, SSH login, root partition growth, and `nixos-version` before claiming ECS readiness.

Clean up temporary ECS validation resources in dependency order: release the instance, delete the custom image when unused, delete the staging OSS object, delete a task-specific bucket only if empty, and remove any temporary SSH ingress rule created outside Terraform.

## Host-Local Package Pattern

For one-off, host-specific CLI or GUI package requests on `axiom`, prefer the existing host-local `user.packages` list over introducing a reusable module. Use a reusable module when the app/tool needs cross-host enablement, NixOS service integration, firewall/system settings, generated config, or runtime policy ownership.

CLI package-only installation should not imply declarative service/config integration. For secrets tooling specifically, installing `sops` is not the same as adopting `sops-nix`; evaluate agenix coexistence, migration, identity source, rollback, and secret ownership in a separate scoped task.

Package-only GUI client installation should not imply account state, proxy setup, cache management, autostart, credentials, organization policy, or live `nixos-rebuild switch` unless the task contract explicitly includes those runtime concerns.

If a GUI package later proves to require runtime service ownership, split a follow-up task rather than silently expanding the original package-install scope. For remote-access clients, prefer a host-local systemd service only after live diagnostics identify the required background process, run it as the desktop user when that is sufficient, restrict any shared state directory that may contain auth/private data, and avoid firewall changes unless they are explicitly scoped and security-reviewed.

For unfree or FHS-wrapped GUI clients from `pkgs.unstable`, validate the evaluated host user package list, the package build itself, and the host toplevel dry-run. This proves declarative installation and rebuild planning without claiming GUI login, extension marketplace, or runtime state behavior.

For flake-sourced GUI clients such as Sidra, a small reusable app module is acceptable when the upstream package is best consumed as a flake and may be enabled on more than one desktop host later. Keep the first integration package-only unless runtime service/config ownership is explicitly scoped, pin the upstream flake in `flake.lock`, make it follow the repository's existing nixpkgs baseline when possible, and validate the target host toplevel build before claiming installation readiness.

For Axiom Playwright tooling, prefer enabling the existing `modules.dev.playwright` module over manually adding `pkgs.playwright-test` to host-local packages. Validate the evaluated host option, evaluated `users.users.c1.packages`, CLI version, wrapper `PLAYWRIGHT_BROWSERS_PATH`, and Axiom toplevel dry-run; live browser launch remains a post-switch graphical-session smoke check.

For Playwright runtime fixes on NixOS, validate both browser paths. The Nix-packaged `playwright` wrapper proves the nixpkgs browser path, while a project-local npm/npx Playwright install with an isolated `PLAYWRIGHT_BROWSERS_PATH` proves downloaded Ubuntu fallback browsers can resolve their shared libraries through the evaluated `nix-ld` library set. This avoids the false positive where the wrapper works but npm/npx Chromium still fails on missing libraries such as `libglib-2.0.so.0`.

For VSCode extension fixes that need to be persistent in Nix, prefer a `vscode-with-extensions` wrapper around the existing VSCode package rather than relying on mutable `$HOME/.vscode/extensions` state. Remember that the wrapper passes a generated `--extensions-dir`, so manually installed extensions are not the source of truth under that launcher. Declare the target extension and any required `extensionPack` members explicitly, then validate the target host user package list, build the wrapper package, inspect the wrapper `--extensions-dir`, and confirm the generated extension directory contains the expected publisher/name directories. Live extension activation remains a post-deploy graphical smoke check.

For VS Code keyring prompts under Hyprland, first validate that `org.freedesktop.secrets` is available on the user bus and that the host enables `gnome-keyring`. If the Secret Service backend exists but VS Code still cannot identify an OS keyring, prefer a VS Code package-level `commandLineArgs = "--password-store=gnome-libsecret"` override. This keeps terminal and desktop-entry launches consistent through the same wrapper and avoids global `XDG_CURRENT_DESKTOP` spoofing or weaker encryption.

## Host Service Modularization Pattern

For NixOS host files, keep durable host facts in the host and move repeated service mechanics into focused modules. Good module candidates are systemd service wrappers, restart/OOM policy, healthcheck timer/counter/restart loops, public ingress glue, and status endpoint generation. Do not keep old inline service shapes as compatibility aliases unless another checked-in host actively consumes them.

For public loopback services, prefer a single service module declaration that owns the local systemd service and optionally contributes Gatus endpoints and Cloudflared ingress. This keeps the app port, public hostname, and monitoring target from diverging across host, tunnel, and status-page sections.

For Cloudflared tunnel config, model ingress as first-class module data and keep host `extraConfig` for connector-level knobs such as metrics, protocol, and tunnel metadata. Keep local services bound to `127.0.0.1` and remove broad firewall ranges unless a service module or reviewed host fact requires them.

For root-run timer healthchecks that restart local services after repeated failures, share the counter/threshold/restart skeleton and keep only the functional predicate host-specific. Remote cleanup remains out of scope unless a separate design proves it safe.

For host files that still contain large script bodies after service extraction, continue one level deeper before calling the host modular: mutable user-config migrations belong in the owning desktop module, hardware/session readiness scripts belong in a focused desktop/hardware module, remote-access runtime services belong in a service module, and VM stack policy belongs in a virtualization module. The host should pass card names, sink names, app ids, remote host/port facts, hostnames, labels, and enablement flags.

For healthchecks, prefer typed predicates over host-owned shell bodies when the predicate shape is reusable. Current reusable shapes are HTTP readiness, autossh endpoint-key comparison, and service-core/interface health. Keep raw `check` script support for genuinely one-off predicates, but do not use it as the default for common daemon checks.

For permission policy moved out of hosts, default the module option to disabled and require explicit host enablement. Preserve fixed action allowlists and local subject/user checks; do not turn a host-local polkit rule into group membership, prefix grants, sudo wrappers, or broader default module behavior.

For host policy extraction after scripts are gone, keep moving ownership to the closest domain module rather than adding a generic catch-all policy module. Status-page endpoint inventory belongs in the status/Gatus module; service restart/OOM policy belongs in the owning service/app module; workstation zram/logrotate/user-manager defaults belong in the workstation profile; LAN-only firewall rules belong behind typed firewall helpers. Hosts should keep facts such as hostnames, endpoint names, CIDRs, ports, interface names, and memory thresholds.

When moving firewall or resource policy, validate the effective generated config rather than only checking build success. For firewall, prove source CIDR, protocol, and ports. For service survival policy, prove `OOMScoreAdjust`, `MemoryMin`, `MemoryLow`, restart policy, and any `StartLimitIntervalSec` on the generated systemd unit.

## Runtime Entry Validation

For display-manager runtime regressions, validate the effective NixOS session data rather than guessing desktop entry names. Check `services.displayManager.sessionData.sessionNames`, the generated `share/wayland-sessions/*.desktop` entries, and the consumer command that references them.

For NetworkManager/iwd changes, validate service ownership explicitly: NetworkManager backend/DNS, iwd `EnableNetworkConfiguration`, resolved enablement, legacy DHCP service presence, and any generated NetworkManager ensure profiles.

For PipeWire/EasyEffects startup regressions, separate hardware-path proof from session-routing proof. First test the actual ALSA device, then inspect the PipeWire/Pulse default sink, app sink-inputs, EasyEffects virtual sink links, generated systemd user ordering, and whether a real `pulseaudio --start` process is holding `/dev/snd` outside PipeWire. If HDMI works directly but apps attach to EasyEffects before a real hardware sink exists, prefer a declarative startup-order/default-sink fix plus PulseAudio autospawn prevention over manual `pactl` repair commands.

For Hyprland config syntax migrations, do not rely on Nix build/eval alone. Build a combined config from generated pre config, checked-in base config, and generated post/theme config, then run the evaluated Hyprland binary with `--verify-config`.

For Hyprland monitor mode changes, directly evaluate the generated Home Manager `hypr/monitors.conf` text for the target host. This proves the active Nix startup rule requests the intended fallback mode without confusing it with checked-in source defaults. For dynamic hotplug policy, also evaluate `modules.desktop.hyprland.monitors` and `monitorHotplug`, build the Home Manager activation package and NixOS toplevel to realize generated helpers/services, syntax-check generated shell helpers, and test native-resolution/highest-refresh selection with static `hyprctl monitors all -j` samples. When adding optional monitor fields such as `bitdepth`, `cm`, `sdrbrightness`, or `sdrsaturation`, use a temporary `extendModules` override to validate the generated `monitorv2` shape; still record that real refresh rate, HDR behavior, and physical hotplug require a live Hyprland smoke.

For visible-shell startup regressions where Hyprland shows a cursor but the desktop stays black, validate the generated startup chain directly. Check that `exec-once = hey hook startup` is present, startup hooks are ordered as expected, the early session hook starts `hyprland-session.target`, DMS/Quickshell is wanted by the session target, wallpaper starts through the configured background hook, and no foreground lock command gates the shell path.

For Hyprland/UWSM startup warnings, validate the actual command resolution instead of only checking desktop entry existence. A `uwsm start` dry run should resolve to `start-hyprland`; if it resolves to direct `Hyprland`, the generated startup path can still trigger the upstream warning even when UWSM is present.

For autossh reverse tunnel regressions, validate both sides of the generated shape: the remote-forward string must remain loopback-only and port-unique, and the local target service must exist as an active daemon if the tunnel forwards to `127.0.0.1:22`.

For workstation desktop/CLI mode switches, prefer a custom systemd target over disabling desktop modules at runtime. The CLI target should require `multi-user.target`, conflict with `graphical.target`, explicitly want a local getty when a physical console fallback matters, and set `AllowIsolate=true`. The switching command should use fixed target names for `systemctl set-default` and `systemctl isolate`, then validate the generated target relationships and the services that must remain under `multi-user.target`.

For frp token-auth tunnels, keep credential material out of Nix store by generating checked-in templates with a placeholder and rendering the final TOML under `/run/<service>` from an agenix path at service start. Validate the target host evals, dry-run builds, generated proxy port, firewall allow-list, render script contents, frp's own `verify` command, and encrypted token consistency without printing the token.

If a host-local control CLI grows beyond a trivial package list entry, make it a real package rather than a large inline `writeShellScriptBin` in the host. Current control-CLI ownership is `c1ctl` under `packages/c1ctl`: Nix injects the `systemctl` store path for fixed privileged mode switching and injects the existing `hey` path for compatibility delegation. Dynamic script dispatch in Rust must use argv arrays, a constrained namespace parser, and the `hey` child environment contract (`DOTFILES_HOME`, computed `PATH`, `HEYSCRIPT`, `HEYDRYRUN`, `HEYDEBUG`). Treat Rofi as a special exact delegation boundary (`@rofi` delegates whole to Janet) and keep unported mutating command families delegated until their own parity and rollback evidence exists.

For XDG SSH wrapper regressions, build and inspect the generated wrapped `ssh` script. The wrapper must expand `XDG_CONFIG_HOME` at runtime, fall back to `$HOME/.config`, pass `-F "$cfg"` as argv elements rather than as a literal `$XDG_CONFIG_HOME/ssh/config` string, and set a portable `TERM` such as `xterm-256color` when local terminals like Foot would otherwise leak terminfo names many remote hosts lack.

For opencode over cloudflared, keep the app server bound to `127.0.0.1`, route the public hostname through cloudflared ingress, and treat Cloudflare Access policy verification as a separate上线前置条件. DNS route creation proves the tunnel hostname exists; it does not prove Access policy or app authorization.

For NixOS-native Gatus status pages, keep the wrapper minimal around upstream `services.gatus`: enable metrics, set sqlite storage, bind `web.address` to `127.0.0.1`, proxy public access through nginx, and append Prometheus scrape configs only when Prometheus is enabled. Let upstream `DynamicUser=true` and `StateDirectory=gatus` own state; do not add custom tmpfiles rules for `/var/lib/gatus` unless upstream state handling changes.

Validate status-page changes with the target host toplevel build plus focused evals for Gatus settings, nginx vhost, endpoint inventory, and Prometheus scrape configs. Full flake checks are useful but should be classified separately if they fail on unchanged baseline app/schema wiring.

For Cloudflare secrets, keep cloudflared tunnel runtime credentials separate from Cloudflare API management tokens. `cloudflared-credentials.age` should remain the tunnel credentials JSON (`AccountTag`, `TunnelSecret`, `TunnelID`, `Endpoint`); API automation tokens should use a separate env-style age secret and validation should pattern-match decrypted output without printing secret values.

For Linux cloudflared services backed by agenix credentials, keep connector config system-owned, for example `/etc/cloudflared/config.yml`. Do not require Home Manager to write `~/.cloudflared/config.yml` if the age secret path also lives under `~/.cloudflared`, because agenix can create the parent directory as root before Home Manager activation.

For terminal config compatibility regressions, validate the repository source and the Nix-evaluated Home Manager source path with the target terminal binary. For Foot, `foot --check-config --config <path>` is the direct validation surface; do not assume an option remains valid across package upgrades just because an older checked-in config accepted it.

For shell/terminal ownership migrations out of a theme module, combine content reference search with path-level orphan checks. Reference greps such as `fonts\.terminal` or `hey info theme fonts terminal` prove consumers moved, while `git diff --name-status -- 'modules/themes/*/config/zsh/*' 'modules/themes/*/config/tmux*'` and a worktree glob prove stale theme-owned prompt/tmux assets were not left behind. Also evaluate the new owner metadata, for example `hey.info.term.font`, and at least one desktop plus one server host that enable the affected shell/terminal modules.

For GUI-launched terminal or app command lookup regressions that do not reproduce over SSH, validate graphical session PATH ownership rather than patching shell rc files first. Check generated `uwsm/env`, the Hyprland startup `systemctl --user import-environment` list, relevant launcher service `path` entries, and whether the missing commands live in `config.environment.systemPackages` or user packages.

For out-of-band user tools such as opencode under `$HOME/.opencode/bin`, validate both interactive shell startup and generated desktop session PATH. Avoid literal `environment.variables.PATH` strings as the only integration surface; prefer explicit shell path initialization plus generated `uwsm/env` evidence.

For Axiom Keep Awake changes, prefer Caelestia's native `idleInhibitor` over custom no-sleep wrappers when the requirement is manual graphical-session idle inhibition. Hypridle should remain scoped to idle lock and DPMS for the current Axiom default: validate the checked-in config has the 15 minute lock listener, the 30 minute DPMS off/on listener, and no `$suspend_cmd`, `systemctl suspend`, `loginctl suspend`, or automatic suspend listener. Also validate Caelestia's generated `general.idle.timeouts` and persisted shell-config migration are aligned to 900 second `lock` and 1800 second `dpms off` / `dpms on` entries with no 600 second sleep/suspend/hibernate action; changing only the seed settings is insufficient for an already-existing mutable `~/.config/caelestia/shell.json`. Validate there is no Axiom startup hook or helper that runs `idleInhibitor enable` by default, absence of stale `axiom-sleep-mode` packages/launchers/direct Hypridle overrides/sleep-inhibitor services, and README documentation of the graphical-session boundary. If a future task restores stronger default never-sleep behavior or default Keep Awake, require a new scoped contract and validation plan rather than reviving historical inhibitor wiring implicitly. Avoid triggering live suspend or hibernate in tool sessions; record those as post-deploy Hyprland smoke checks.

For Steam HiDPI regressions on fractional-scale Hyprland, validate both compositor and application surfaces: generated `xwayland.force_zero_scaling`, the actual wrapped `bin/steam` script exporting `STEAM_FORCE_DESKTOPUI_SCALING`, Steam package closure presence, assembled `Hyprland --verify-config`, and the host toplevel build. Live crispness remains a deployment smoke check.

For Steam compatibility tools supplied by an external flake, keep the integration behind a module-level opt-in and wire the selected package through `programs.steam.extraCompatPackages`. Validate the opted-in host option, the evaluated compatibility package names, a representative non-opted-in Steam host's empty/default list, the selected package build, and the target host toplevel build. Live Steam UI selection remains a post-deploy smoke after system switch and Steam restart.

For Fcitx5 Wayland frontend warnings about `GTK_IM_MODULE`, validate the evaluated input method frontend and the managed environment separately. Check `i18n.inputMethod.fcitx5.waylandFrontend`, then confirm `GTK_IM_MODULE` is absent from both `environment.sessionVariables` and `environment.variables`; do not patch host shell files before proving the Nix-owned environment source.

For Fcitx5 theme alignment on Axiom, follow the current Caelestia visual direction before choosing a theme package. Current Axiom uses generic Fcitx theme package/name selection with `fcitx5-fluent` and `Theme=FluentDark`, while preserving Catppuccin defaults for other users. Validate both `i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection.Theme` and the generated `fcitx5/conf/classicui.conf`; do not touch Rime schemas, dictionaries, or private input data for a color-only task.

For Thunar/GTK contrast regressions under Caelestia, prefer package-level GTK theme alignment with the active qtengine direction before writing app-specific GTK CSS. With qtengine on KDE `BreezeDark.colors`, the current GTK counterpart is `Breeze-Dark` from `kdePackages.breeze-gtk`; validate Home Manager GTK theme name/package, Axiom theme metadata, and the host toplevel. If live Thunar still shows light surfaces or unreadable text while `Breeze-Dark` is selected, inspect `~/.config/gtk-3.0/gtk.css` and imported Thunar CSS for stale generated overrides, then make the repository own only the necessary GTK3 CSS files with Thunar-scoped theme-variable rules. Perceived contrast remains a post-switch graphical smoke.

For NixOS GUI apps that also ship service/TUN installers, prefer the upstream NixOS module over mutable GUI installer flows. Validate the actual exposed option names with `nix eval ...options.<module> --apply builtins.attrNames`, because this repository disables strict module option checking and inert settings can otherwise be silently ignored.

For Clash Verge Rev specifically, validate `programs.clash-verge.serviceMode`, `tunMode`, `autoStart`, the generated `clash-verge.service` `ExecStart`, capability bounding set, `networking.firewall.trustedInterfaces`, `extraReversePathFilterRules`, and the host `system.build.toplevel.drvPath`.

For local Clash/Mihomo controller helper scripts, prefer loopback defaults, runtime-only secret inputs, and mock-controller validation. Verify `GET /proxies` response parsing, target group `all[]` extraction, `PUT /proxies/<group>` request bodies, ambiguous node-name handling, and non-TTY interactive guards without changing the live workstation proxy selection unless a task explicitly scopes a live switch smoke test.

## Critical Network Resilience Pattern

For workstation remote-access and network-control services that must survive memory pressure, validate both kernel OOM selection and cgroup pressure behavior. `OOMScoreAdjust` is the primary proof for global OOM priority; `MemoryMin` and `MemoryLow` are cgroup reinforcement. Do not claim a service is protected if only one layer was checked.

For active-but-broken daemons, pair `systemctl active` with a functional health predicate. For cloudflared, check `/ready` and make the metrics endpoint explicit in generated config. For reverse SSH, prove the remote endpoint reaches the intended local host by comparing the host key exposed through the reverse port against the local host public key; a generic `SSH-2.0` banner is not enough.

Timer-driven healthchecks that run as root may restart local system services after repeated failures, but should not perform irreversible remote cleanup without a separate reviewed design. If remote listener evidence is useful, log bounded `ss` output for the exact reserved port and leave cleanup manual.

When validating generated healthchecks before deployment, combine the target host toplevel build, focused Nix evals, generated unit inspection, `systemd-analyze verify`, shell syntax checks, and safe live predicates. Do not force OOM stress or failure-threshold restarts on the live workstation unless the task explicitly scopes destructive testing.

## 上游桌面参考采用模式

使用大型外部桌面 dotfiles 仓库作为产品灵感时，应先提取能力，再考虑代码移动。需要把 compositor/session model、shell ownership、notification/search/control surfaces、theming、state writes、dependency assumptions 和 rollback boundaries 与 Axiom 当前 Nix-native model 对比。

不要导入 mutable installers、distro package-manager logic、generated user state，或与 Axiom UWSM/systemd ownership 冲突的 session assumptions。优先采用分阶段本地能力等价；在 shell-native replacements 验证前，保留外部工具作为 fallback。

## Quickshell Notification Center Pattern

For Axiom notification UI, keep `NotificationServer` as the ingress and use `trackedNotifications` as the runtime source of truth. Keep notification history session-local unless a task explicitly defines retention, clear behavior, disable switches, and privacy handling.

When validating new Quickshell QML files from a Git-backed flake, stage or intent-to-add the new files before `nix eval`/`nix build`, then pair Nix build evidence with a real-session test plan. Headless/offscreen Quickshell can fail at `No PanelWindow backend loaded`; treat that as an environment limitation, not a substitute for Hyprland layer-shell testing.

Keep Quickshell `Variants` composition simple: use one per-screen `PanelWindow` delegate per `Variants` block. If multiple windows need the same screen model, create separate `Variants` blocks or an explicit wrapper component; do not add sibling `PanelWindow` delegates in one `Variants` block.

## Quickshell Search and Actions Pattern

For Axiom shell-owned search/actions, keep the visible UI in Quickshell and keep provider execution behind fixed local verbs. QML may compose results and invoke reviewed argv arrays or repository-owned helper subcommands, but it should not parse desktop-entry `Exec` strings into shell commands or pass user query text to `sh -lc`.

Search providers should be independently bounded: app launch validates desktop IDs against scanned entries, calculator input is parsed as data through a restricted expression evaluator or equivalent local backend, emoji data stays local/offline, web search only opens an encoded user-requested URL, and clipboard history has explicit caps, clear, disable, and rollback behavior.

Fallback-first rollout remains required for launcher replacements. Keep Fuzzel available through a direct action and binding until the Quickshell search panel, IPC/focus behavior, and real app/clipboard actions are verified in an Axiom Wayland session.

When verifying Quickshell search changes headlessly, treat Nix eval/build, helper smoke tests, scope grep, `git diff --check`, and `Hyprland --verify-config` as useful evidence, but record that `PanelWindow` runtime behavior still requires a real layer-shell session.

## Quickshell Quick Controls and OSD Pattern

For Axiom quick controls, prefer a Quickshell-owned panel plus a narrow fixed-verb helper over deep QML/DBus control-center logic. The first pass should show useful status, expose common safe actions, and keep full settings apps as visible fallbacks rather than implementing Wi-Fi onboarding, Bluetooth pairing, or audio device switching in one task.

OSD wrappers must preserve the underlying state change before attempting shell polish. Volume and brightness can continue through `hey .osd` / `pamixer` / `brightnessctl`; media key wrappers should run fixed `playerctl` verbs before attempting Quickshell IPC. If IPC or Quickshell fails, existing `notify-send` or direct command fallback remains the rollback path.

For verification, pair static checks (`qmllint`, helper syntax/smoke, `zsh -n`, Nix eval/build, `Hyprland --verify-config`, scope/fallback greps, and `Variants`/`PanelWindow` counts) with a live-session checklist. Headless validation cannot prove panel focus, layer placement, rapid OSD timing, or disruptive actions such as Wi-Fi/Bluetooth toggles, lock, DPMS off, and `wlogout`.

## Caelestia Shell Integration Pattern

When adopting Caelestia Shell on Axiom, consume the upstream `caelestia-dots/shell` flake package instead of vendoring shell source or running mutable setup scripts. Prefer `packages.<system>.with-cli`, because the upstream default package omits full CLI support.

Keep a small local NixOS integration module as the repository boundary: install the shell and CLI package, seed minimal `caelestia/shell.json` defaults into a mutable user file, start the generated `caelestia-session` runner from the Hyprland startup hook after `hyprland-session.target` environment import, and keep reload/restart hooks inside the repo's existing session ownership model.

When Caelestia owns wallpaper, keep it as the only wallpaper owner. Gate the Hyprland `swaybg` hook off, enable `background.wallpaperEnabled` in generated `caelestia/shell.json`, and seed the mutable Caelestia wallpaper state from the `caelestia-session` pre-start path. If the canonical wallpaper is too large for Qt image IO, generate a display-safe derivative under Caelestia's state directory and update `path.txt` only when it is missing, empty, or still points at the known oversized source.

Caelestia Shell is a launcher and helper process parent, so its session runner needs an explicit runtime PATH that includes `app2unit`, CLI/helper tools such as `util-linux`, user application packages, and generated system packages when those packages provide desktop-entry commands or terminal-visible tools. It also needs Nix-aware `XDG_DATA_DIRS` coverage for package `share/applications` paths when Quickshell `DesktopEntries` is expected to discover Nix-installed GUI apps. Nix build success alone does not prove launcher subprocesses can start or that app discovery can see package desktop entries if the runner environment is still minimal.

Caelestia Shell launcher children need the active display/session environment as well as PATH and XDG data dirs. For X11-first apps such as Steam, validate `DISPLAY` on the launcher parent (`caelestia-session` / `quickshell`), the systemd user manager environment, direct XWayland connectivity (`xrandr` or equivalent), and recent app logs before changing the app package or GPU/runtime settings. Prefer hydrating missing display variables from the systemd user manager with a fixed allowlist instead of hard-coding `DISPLAY=:0` or importing arbitrary environment.

Prevent duplicate shell ownership by using quickshell `--no-duplicate` and the generated `caelestia-session` restart/stop command. Avoid Hyprland keybinds that directly launch the shell binary, because they create unmanaged instances outside the reviewed session runner.

Expose standard desktop icon and MIME fallback packages with the local Caelestia integration when the shell is the active product surface. `hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, and `xdg-utils` should be in the Axiom user package closure so Qt/app launcher/tray icon lookup does not fall back to checkerboard placeholders.

For README-aligned Caelestia setup on a new Axiom machine, set `QT_QPA_PLATFORMTHEME=qtengine` in generated Hyprland env, generated UWSM env, the Caelestia session runner environment, session variables, and the systemd user import path. Provide `qtengine` through the locked `kossLAN/qtengine` flake input and validate `programs.qtengine.enable`, generated env files, the generated `caelestia-session` script, an assembled Hyprland `--verify-config` using the evaluated package, and the Axiom toplevel build. Treat the prior `qt6ct` color-block workaround as historical unless a future live regression explicitly reopens it.

Keep Caelestia shell.json defaults intentionally small. For README-style font and app defaults, seed `appearance.font.family` and `general.apps.explorer = ["thunar"]`, but do not copy the whole upstream example config into this repository. Because `shell.json` is user-mutable on Axiom, repository changes should only replace missing files or old `/nix/store` symlinks and must not overwrite an existing real user config.

For Caelestia launcher favourites, prefer Quickshell `DesktopEntry.id` values over duplicate desktop files. For top-level desktop files, Quickshell derives the id from the complete basename, so `share/applications/bytedance-feishu.desktop` is favourited as `bytedance-feishu`, not `bytedance-feishu.desktop`. Declare the desired default in `modules.desktop.caelestia.settings.launcher.favouriteApps`; when an existing mutable `shell.json` must be updated, use `modules.desktop.caelestia.mutableConfig` to append/correct the target id and leave other user settings untouched. Because favourites are sorted entries, not discovery inputs, validate that the Caelestia runner exposes package `share` paths through its XDG data dirs before diagnosing deeper launcher bugs. Validate the favourite setting, mutable migration behavior, package presence, desktop-entry existence, session runner XDG data dirs, and Axiom toplevel; live menu visibility still needs a real-session smoke check.

Mutable Caelestia `shell.json` migrations should live in `modules.desktop.caelestia.mutableConfig` rather than host-local pre-start scripts once they are part of the durable shell integration. Keep the repository seed small, deep-merge only the configured settings, append desired launcher favourites idempotently, remove known legacy IDs narrowly, and preserve unrelated user settings.

Put font policy in the theme/fontconfig layer. Caelestia should expose the requested shell family names, Foot should derive its font from the theme terminal font, and CJK fallback families should be declared through `fonts.fontconfig.defaultFonts` so non-Caelestia applications share the same fallback behavior.

Use the checked-in Hyprland file as a local base that sources only repository-owned generated config. Host facts such as XKB, monitors, workspaces, rules, default apps, session startup, and fallback keybinds belong in generated `hypr/custom/*.conf` files rather than in upstream shell source or live-home edits. Generated Hyprland keybind modifiers should use canonical uppercase names, especially `SUPER`, before diagnosing deeper input-stack failures.

When a Caelestia safe-mode report follows screen-off, DPMS, monitor power, or suspend/resume events, inspect Hyprland first: check `coredumpctl`, `/home/c1/.cache/hyprland/hyprlandCrashReport*.txt`, `caelestia-session status` / Quickshell logs under `/run/user/1000/quickshell`, and `journalctl --user -u hypridle.service -u hyprland-session.target`. If Hyprland coredumps before Caelestia reports `The Wayland connection broke`, classify Caelestia as a downstream casualty. For Hyprland 0.53.x `NColorManagement::CImageDescription::id()` crashes, prefer the Axiom-local `render.cm_enabled = false` mitigation until the pinned package includes the upstream fix; verify with generated config eval, assembled `Hyprland --verify-config`, Axiom toplevel build, and a post-deploy DPMS/resume smoke.

Systemd-owned Hyprland helper services need explicit PATH coverage for commands embedded in checked-in configs. `hypridle.service` should be able to resolve `hyprctl`, `caelestia`, and `caelestia-shell` from Nix store paths for the current Caelestia WlSessionLock plus DPMS idle policy; do not rely on an interactive shell PATH for idle lock or DPMS commands. Only require `systemctl` or `loginctl` there if a future task explicitly reintroduces an automatic suspend command or logind lock route.

For Axiom shortcut reference features, keep both the visible entrypoint and the help content in repository-generated Hyprland integration. Bind the physical slash key as Hyprland keysym `slash`, present it to users as `SUPER+/`, generate helper scripts with fixed Nix store paths, and validate with focused keybind evals, realized helper/text inspection, an assembled `Hyprland --verify-config`, the Axiom toplevel build, and `git diff --check`. Live chord behavior still requires deployment in the real Hyprland session.

For Axiom Hyprland mouse keybind changes, validate both generated keybind presence and parser syntax. A focused Nix eval should prove `bindm` or `mouse_up`/`mouse_down` lines exist in generated `hypr/custom/keybinds.conf`, and an assembled `Hyprland --verify-config` should still return `config ok`. Document live physical mouse behavior as a post-deploy smoke check when the task runs outside the graphical session.

Validate Caelestia migrations by evaluating the upstream `with-cli` package, generated `caelestia-session` control command, seeded `caelestia/shell.json` defaults or seed script, user package closure, active Hyprland keybinds, and absence of active end4 references outside historical `.legion/tasks/**`. Always run an assembled `Hyprland --verify-config` after changing generated keybinds or rules; Nix build alone does not catch parser restrictions such as top-level `catchall`. Pair static evidence with a live Hyprland session smoke when available; headless builds cannot prove layer-shell rendering, tray, launcher focus, icon rendering, OSD, screenshot, lock/session behavior, physical Super-key recognition, or polkit subject classification.

When Caelestia global-shortcut dispatch is the reported failure, prefer reviewed CLI IPC keybinds for drawers, brightness, media, and picker actions over reworking DBus/global-shortcut plumbing in the same task. Validate command names against the current Caelestia package source or `caelestia shell -s`, and keep direct shell process starts out of Hyprland keybinds.

When Caelestia/Quickshell controls fail on power or Wi-Fi actions, validate polkit subject classification, the Caelestia process cgroup under `session-*.scope`, and evaluated `security.polkit.extraConfig` before changing shell code. Prefer local-subject, primary-user, fixed-action allowlists for required NetworkManager/logind actions; avoid broad `networkmanager` group membership, prefix grants, sudo wrappers, and direct upstream QML mutation.

For Caelestia lock/session regressions, treat `loginctl lock-session` as a separate integration path from Caelestia's direct lock IPC. Ordinary idle/keybind locks should call `caelestia shell lock lock`, which sets the shell's `WlSessionLock.locked` state. If that path regresses, investigate the session-owned shell runner, Quickshell IPC, PAM configs embedded in the Caelestia package, and Hyprland session-lock restore behavior before reintroducing an external lock client.

## Historical End4 Desktop Import Pattern

When adopting end4 desktop phases in Axiom, treat the upstream `ii` source tree as product source once substrate-only is rejected. Import required upstream files through a manifest, record upstream commits and submodules, and keep omitted installer/generated/secret/state paths explicit.

The target UX can be end4 `ii` / `IllogicalImpulseFamily`, but Nix must still own host facts, UWSM/greetd/portal startup, package closure, system services, user services, groups, kernel modules, keyring/polkit, generated override files, and generated-state boundaries.

Do not use old Axiom shell affordances as compatibility requirements once an end4 phase explicitly supersedes them. It is acceptable to keep transitional helper code alive for currently checked-in shell sources, but task docs and wiki must mark that code as migration debt rather than current product truth.

For large QML imports, pair Nix eval/build with a local QML import scan and a bounded headless Quickshell smoke. If the smoke reaches `ii/shell.qml` and then fails at `No PanelWindow backend loaded`, record that as a TTY/offscreen compositor limitation, not as live layer-shell validation.

For imported end4 QML dependencies, validate that wrapper paths contain real module trees. KDE package names can point at wrapper/metadata derivations; if QML imports fail at runtime, add the corresponding unwrapped QML package path and export both `QML2_IMPORT_PATH` and `QML_IMPORT_PATH` from the wrapper.

Keep host-level Hyprland facts in generated `hypr/custom/*.conf` files sourced after upstream end4 config. This is the right layer for Axiom XKB layout/variant/options and host hotkeys such as end4 search/sidebar IPC bindings, because imported upstream defaults may otherwise override local workstation facts.

For `cliphist` adoption, distinguish shell display/readback limits from database retention. `wl-paste --watch cliphist store` proves the backend wiring, but privacy readiness still requires a retention/clear policy and live-session verification.

For end4 live-polish fixes, validate process integration as well as QML imports. Check generated Hyprland bindings, Quickshell IPC targets, service `ExecStart`, service PATH package closure, wallpaper/theme output directories, and the Home Manager source path before relying on live smoke tests.

Use real no-op IPC liveness handlers for fallback probes. A missing or placeholder target can make every fallback path run even while Quickshell is alive, which can hide the intended panel and launch unrelated tools.

When imported shell code writes preview images, screenshots, clipboard decodes, or generated theme state, prefer XDG cache/state paths and ensure parent directories exist before helper processes run. Avoid shared `/tmp` paths for persistent shell integration unless a task explicitly scopes cleanup and collision behavior.
