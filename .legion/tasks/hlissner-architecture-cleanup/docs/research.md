# Research: Hlissner-aligned Dotfiles Architecture Cleanup

## 1. Problem Restatement
本仓库已经继承 hlissner/dotfiles 的轻量自制 flake/module/host 框架，但在 Darwin 兼容、Axiom Wayland/Caelestia 桌面产品化、Cloudflare/remote access 与 Legion 文档流上积累了本地扩展。当前问题不是缺少功能，而是边界逐步变厚：平台 env 发射重复、host-local 与 reusable module 的职责不够显式、Hyprland/Caelestia 常量和生成文件逻辑集中在大模块里，后续改动容易引入行为漂移。

影响范围是代码组织、Nix module assembly、生成配置文本和验证方式。默认目标是行为保持；用户允许极小行为调整，但任何调整必须被显式设计、记录和验证。

## 2. Relevant Code / Entry Points
- `flake.nix:60-100` - 当前 flake 入口保持 `import ./lib` + `mkFlake inputs` + `mapHosts ./hosts` + map checks/overlays/packages 的 hlissner 风格，同时扩展 Darwin/system inputs。
- `lib/default.nix:37-51` - 动态加载 `lib/*.nix` 并 flatten namespaced helpers；`lib/default.nix:44-46` 仍有 lexicographical loading 的 FIXME。
- `lib/modules.nix:7-20`、`lib/modules.nix:46-58` - 自动发现模块文件，跳过 `_` 前缀和 `.noload` 目录，是 helper 文件放置边界的重要约束。
- `lib/nixos.nix:174-220` - host metadata/evaluation flow；`lib/nixos.nix:246-318` - NixOS 与 Darwin config assembly。
- `default.nix:11-23` - NixOS base recursively imports all modules and sets `_module.check = false`，这是跨 OS 宽松求值与隐藏无效 option 风险的来源。
- `darwin/default.nix:37-65` - Darwin base 只导入 home/XDG/agenix/cloudflared/shell/dev/editors/theme，不导入 Linux desktop。
- `modules/home.nix:40-69`、`modules/xdg.nix:25-164` - Home/XDG 平台边界，Linux 使用 `environment.sessionVariables`，Darwin 使用 `environment.variables`。
- `modules/desktop/default.nix:16-39`、`modules/desktop/default.nix:83-88` - Desktop umbrella 约束单一 desktop environment，且 X11 baseline 已被主动拒绝。
- `modules/desktop/hyprland.nix:153-194` - Hyprland owns Wayland session, UWSM, portals and desktop type; `modules/desktop/hyprland.nix:316-504` - generated Hyprland/UWSM config surface。
- `modules/desktop/caelestia.nix:112-131`、`modules/desktop/caelestia.nix:184-210` - Caelestia is Linux-only, package/service/config-state owned by local integration module。
- `hosts/axiom/default.nix:10-100` - host intent via `modules`; `hosts/axiom/default.nix:102-230` - host-local services/policies; `hosts/axiom/default.nix:232-269` - hardware facts。
- `config/hypr/hyprland.conf:1-11` - static Hyprland root only sources generated repo-owned config.

## 3. Existing Conventions
- Flake stays thin; orchestration lives in local `lib.mkFlake`, not flake-parts/devos.
- Host files follow the hlissner shape: `system`/`os`, optional `imports`, semantic `modules`, host-local `config`, and hardware/filesystem `hardware`.
- Reusable modules generally expose `options.modules.<domain>.<name>` and gate behavior with `mkIf cfg.enable`; profile modules are tag-driven through `modules.profiles.*`.
- Home Manager is wrapped behind local `home.file`, `home.configFile`, `home.dataFile`, `home.packages` aliases rather than exposing the whole Home Manager surface everywhere.
- `.legion/wiki/patterns.md:61-65` says external desktop dotfiles references should first extract capabilities and must not import mutable installers, generated user state, or session assumptions that conflict with Axiom's Nix-native model.

## 4. Historical Decisions
- `.legion/wiki/decisions.md:5-17` - Current Axiom desktop direction is Hyprland + UWSM + Caelestia Shell. Caelestia supersedes previous end4/DMS/Quickshell product direction, but NixOS owns UWSM/greetd/portal startup, generated config and service wiring.
- `.legion/wiki/decisions.md:21-23` - Axiom session PATH must be generated/imported deterministically; GUI-launched terminals/apps should not rely on shell rc files alone.
- `.legion/wiki/decisions.md:49-55` - Old X11/bspwm/legacy compatibility is not preserved, and Hyprland startup must bootstrap visible product session before lock/wallpaper hooks can block it.
- `.legion/wiki/decisions.md:59-62` - Darwin remains shared shell/dev/editor/XDG only; Linux desktop/system concerns must stay out of Darwin imports.
- `.legion/wiki/patterns.md:3-15` - Git-backed flake validation requires new files to be tracked or intent-to-add before Nix eval/build.
- `.legion/wiki/patterns.md:29-33`、`.legion/wiki/patterns.md:117` - Hyprland config changes require assembled `Hyprland --verify-config`; Nix build alone is insufficient.

## 5. Hlissner Reference Findings
- `/tmp/opencode/hlissner-dotfiles/flake.nix:30-52` - Upstream keeps a smaller Linux-only flake with `hosts = mapHosts ./hosts` and `modules.default = import ./.`.
- `/tmp/opencode/hlissner-dotfiles/default.nix:8` - Upstream root imports all modules recursively, matching this repo's original skeleton.
- `/tmp/opencode/hlissner-dotfiles/lib/nixos.nix:64-128` - Upstream `mkFlake` only builds NixOS configurations and expects host files to provide modules/config/hardware.
- `/tmp/opencode/hlissner-dotfiles/hosts/harusame/default.nix:14-84` - Upstream host composition is readable because intent is grouped under profiles/desktop/dev/editors/shell/services/system.
- `/tmp/opencode/hlissner-dotfiles/modules/desktop/hyprland.nix:133-172` - Upstream uses layered generated Hyprland config (`pre`, colors, post) to separate common config, host facts and extra config.
- Useful ideas to copy as concepts: thin flake, stable host shape, module groups by domain, profile tags, generated config layering, `hey` hook lifecycle, and helper constructors.
- Do not copy as code: upstream Linux-only `mkFlake`, hard `HEYENV` abort, DMS/Quickshell baseline, Rofi launcher assumptions, personal host hardware/secrets, or Linux-only defaults into Darwin paths.

## 6. Constraints & Non-goals
- Preserve flake inputs/lock, host module enablement, secret paths, tunnel IDs, service ports/domains, runtime desktop product and public option names unless the RFC explicitly allows a narrow exception.
- Do not read `token.env` or secret plaintext.
- Do not run deployment commands or auto-merge PR.
- Do not turn `_module.check` on globally in this task; improve validation and local option clarity incrementally instead.
- Do not migrate to a new framework; keep the current hlissner-style custom framework.

## 7. Risks & Pitfalls
- `_module.check = false` can hide moved/missing option mistakes. Mitigation: evaluate concrete host options and inspect generated files/units, not only broad eval success.
- New helper files under `modules/` can be recursively imported unless named with `_` or placed under `.noload`; helper placement must respect `lib/modules.nix` discovery rules.
- Generated Hyprland and UWSM text can change semantically through ordering/quoting even when values are identical. Mitigation: render/evaluate target files and compare intended lines.
- Darwin/Linux env paths differ (`environment.variables` vs `environment.sessionVariables`). Any helper extraction must preserve the existing platform target.
- Caelestia mutable state is intentionally seeded but not continuously owned; cleanup must preserve the “replace missing or Nix-store symlink only” behavior.
- Git-backed flake may ignore untracked new files during validation. Use `git add -N` in the PR worktree before Nix validation if new module/helper files exist.

## 8. Safe Cleanup Seams
- Centralize repeated Wayland/QT/Caelestia env constants used by `modules/desktop/hyprland.nix` and `modules/desktop/caelestia.nix`, while preserving generated file names and values.
- Replace hardcoded home paths in host-local opencode/autossh/service snippets with evaluated `config.user.home` where the resulting strings remain identical for current hosts.
- Use existing platform-aware env helper patterns where they reduce duplicated Darwin/Linux branching without changing target option paths.
- Remove unused/stale comments and dead local helper code, especially in desktop/default and header-only TODOs, without changing Nix expressions.
- Avoid extracting opencode/autossh/cloudflared into reusable modules in the first pass unless the RFC narrows this as a separate milestone; service unit/plist equality would be required.

## 9. Unknowns
- [ ] Which exact validation commands are affordable in the final worktree environment; decide during RFC and record any resource/time limits in `docs/test-report.md`.
- [ ] Whether a strict byte-for-byte pre/post comparison of generated config is practical without a baseline artifact; if not, use targeted `nix eval` and rendered file inspection.

## 10. References
- Plan: `.legion/tasks/hlissner-architecture-cleanup/plan.md`
- Current repo files: `flake.nix`, `lib/default.nix`, `lib/modules.nix`, `lib/nixos.nix`, `default.nix`, `darwin/default.nix`, `modules/home.nix`, `modules/xdg.nix`, `modules/desktop/default.nix`, `modules/desktop/hyprland.nix`, `modules/desktop/caelestia.nix`, `hosts/axiom/default.nix`, `hosts/charlie/default.nix`, `config/hypr/hyprland.conf`
- Current truth: `.legion/wiki/decisions.md`, `.legion/wiki/patterns.md`, `.legion/wiki/maintenance.md`
- Reference clone: `/tmp/opencode/hlissner-dotfiles`
