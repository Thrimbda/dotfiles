# RFC: Hyprland Config Format Migration (.conf → hyprland.lua)

- Task: `dotfiles-hyprland-lua-migration`
- Profile: Standard RFC (medium risk)
- Status: draft → review-rfc

## Context

Hyprland 0.55 deprecated hyprlang config and introduced `~/.config/hypr/hyprland.lua` (Lua via `hl.*` API). 0.56.1 emits a startup warning that `.conf` support will be removed in 0.57. nixos-unstable currently carries 0.56.x, so this repo will break when unstable advances.

This repo generates the Hyprland config from Nix:

- `config/hypr/hyprland.conf` — root that `source=`s seven generated files.
- `modules/desktop/hyprland.nix` — generates `custom/env.conf`, `custom/variables.conf`, `custom/execs.conf`, `custom/general.conf`, `custom/rules.conf`, `custom/keybinds.conf`, `workspaces.conf`, `monitors.conf` via `home.configFile`.
- `modules.desktop.hyprland.extraConfig` — hyprlang lines appended to `custom/general.conf`; used by `modules/themes/autumnal/hyprland.nix`, `hosts/axiom/default.nix`, `hosts/azar/default.nix`, `hosts/ramen/default.nix`, `hosts/udon/default.nix` (axiom: `render.cm_enabled = false` DPMS/resume guard, `misc.allow_session_lock_restore`, `cursor.no_hardware_cursors`; azar: Unknown-1 disable + named workspace pins; ramen: special workspace rules + lid switch binds; udon: Unknown-1 disable + named workspace pins incl. `gapsout`, per-device scroll config, `gaps_out` overscan tweak, HDMI-A-1 startup disable).
- `config/hypr/hypridle.conf` — hypridle's own hyprlang config; hypridle is a separate program and is NOT affected by Hyprland's config format removal.

Verified API facts (official wiki, Hyprland 0.56, fetched 2026-08-19):

- Config entry point: `~/.config/hypr/hyprland.lua`; `require("path")` resolves relative to it; each required file is a separate Lua scope; missing module kills the main config, so all requires must be guaranteed to exist.
- `hl.monitor({ output, mode, position, scale, disabled, bitdepth, cm, sdrbrightness, sdrsaturation })` — replaces `monitor=`/`monitorv2{...}`.
- `hl.env("K", "V")` replaces `env = K,V`.
- `hl.on("hyprland.start", function() hl.exec_cmd(...) end)` replaces `exec-once`.
- `hl.bind(keys, dispatcher, flags)` replaces `bind`/`bindl`/`bindr`/`bindm` (flags: `locked`, `release`, `repeating`, `mouse`).
- `hl.window_rule({ name, match = { class = ... }, workspace = "3 silent", float = true, pin = true, suppress_event = "maximize", immediate = true, idle_inhibit = "focus" })` replaces `windowrule`.
- `hl.layer_rule({ name, match = { namespace = ... }, blur = true, ignore_alpha = 0.79, no_anim = true })` replaces `layerrule`.
- `hl.workspace_rule({ workspace = "1", monitor = "DP-4", default = true, persistent = true, on_created_empty = "..." })` replaces `workspace=`.
- `hl.config({ general = {...}, decoration = {...}, input = {...}, xwayland = {...}, cursor = { default_monitor = ... }, ecosystem = { no_update_news = true } })` replaces category blocks; gradients become `{ colors = {...}, angle = 45 }`.
- `hyprctl reload`, `hyprctl reload config-only`, and `hyprctl keyword` runtime dispatch remain available with Lua config.
- hyprlang `$var` variables have no Lua equivalent; values must be Lua strings/tables inline or returned from required modules.

## Goals / Non-goals

Goals:

- Zero `.conf` files remain in the Hyprland config load path; warning gone on 0.56 and 0.57-ready.
- Same behavior: identical binds, rules, workspace layout, monitor policy, startup ordering.
- Static, repeatable verification before any live deploy.

Non-goals:

- Do not migrate `hypridle.conf` or other Hypr ecosystem tool configs.
- Do not change Caelestia, uwsm env, monitor hotplug scripts, keybinding help text.
- Do not pin Hyprland 0.56.
- Do not live-deploy to azar/ramen/harusame/udon/atlas in this task.

## Options

### Option A — Migrate generated config to required Lua modules (chosen)

Root `hyprland.lua` requires generated `.lua` files in the same order as today's `source=` lines: `custom/env`, `custom/execs`, `custom/general`, `custom/rules`, `custom/keybinds`, `workspaces`, `monitors`. `custom/variables.conf` is deleted; Nix inlines all values. `extraConfig` option changes semantics to Lua and its three users are converted.

- Pros: preserves the file layering and host/theme extension points; each generated file is independently syntax-checkable; 0.57-proof; smallest conceptual change to the module structure.
- Cons: generated `.lua` files must all exist or a require kills the root config; `$var` indirection disappears (acceptable: values are Nix-computed anyway); `extraConfig` semantics change is a config-API break for module consumers (only three, all converted in-repo).

### Option B — Single monolithic generated `hyprland.lua`

Concatenate everything into one file; keep `extraConfig` as an injected string section.

- Pros: no require-scope concerns; trivially atomic.
- Cons: loses per-area layering (rules/keybinds/monitors all in one blob); conflicts with the current theme/host contribution model; large generated file is harder to diff/review; deviates from upstream's recommended multi-file pattern.

### Option C — Pin Hyprland to 0.56.x and defer

- Pros: zero config churn now.
- Cons: warning persists; a hard deadline (0.57 on unstable) turns into an emergency; forfeits 0.56's new Lua-era features. Rejected.

Decision: **Option A**. It is the only option that removes the warning, keeps the module's layered architecture, and follows upstream guidance (`require`-based splitting).

## Decision Details

1. **File layout**: rename each generated `*.conf` entry to `*.lua`; root becomes:
   ```lua
   require("custom/env")
   require("custom/execs")
   require("custom/general")
   require("custom/rules")
   require("custom/keybinds")
   require("workspaces")
   require("monitors")
   ```
   Order preserves today's source order; `execs` (registers `hyprland.start` handler for `hey hook startup`) is required before `workspaces` (registers the xrandr `--primary` handler), matching current exec ordering assumptions.

2. **Mapping** (per file):
   - `env.lua`: `hl.env(...)` lines for the same env pairs.
   - `execs.lua`: `hl.on("hyprland.start", function() hl.exec_cmd("hey hook startup") end)`.
   - `general.lua`: `hl.config({ ecosystem = { no_update_news = true } })`, `hl.config({ input = { kb_layout, kb_variant, kb_options } })`, conditional `hl.config({ xwayland = { force_zero_scaling = true } })`, then `cfg.extraConfig` (now Lua).
   - `rules.lua`: one named `hl.window_rule` per rule (workspace/float/pin/suppress_event/immediate/idle_inhibit) and named `hl.layer_rule` for caelestia/selection layers.
   - `keybinds.lua`: `hl.bind` with dispatcher objects (`hl.dsp.exec_cmd`, `hl.dsp.window.close`, `hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })`, `hl.dsp.focus({ workspace = n })`, `hl.dsp.window.move({ workspace = n })`, `hl.dsp.window.drag()/resize()` for mouse binds); flags: `locked` for old bindl, `release` for old bindr, `mouse` for old bindm; `$caelestia`/`$browser`/`$fileExplorer`/`$terminal` inlined from Nix.
   - `workspaces.lua`: `hl.config({ cursor = { default_monitor = <primary> } })`, xrandr primary via `hyprland.start` handler, `hl.workspace_rule` for workspaces 1..10 (and 11..20 when secondary enabled) with `default`/`persistent` on 1/11.
   - `monitors.lua`: `hl.monitor(...)`; `disabled = true` for disable; advanced fields (bitdepth/cm/sdrbrightness/sdrsaturation) become direct fields; Nix monitor policy (mode/fallback/scale/position) unchanged.
   - `variables.conf` deleted.

3. **`extraConfig` consumers converted**:
   - axiom: `hl.config({ render = { cm_enabled = false } })`, `hl.config({ misc = { allow_session_lock_restore = true } })`, `hl.config({ cursor = { no_hardware_cursors = true } })` (all three option names verified present in the 0.56 wiki Variables page).
   - autumnal theme: `hl.env` for HYPRCURSOR_THEME/SIZE, `hl.config` for general/decoration (gradient borders become `{ colors = {...}, angle = 45 }`), `hl.layer_rule` for caelestia namespace.
   - azar: `hl.monitor({ output = "Unknown-1", disabled = true })` + two `hl.workspace_rule` (name:left/name:right with monitor/default).
   - ramen: two special-workspace `hl.workspace_rule` (gaps_in, gaps_out as css table, `on_created_empty`), lid-switch `hl.bind("switch:on:/off:Lid Switch", ..., { locked = true })`.
   - udon: `hl.monitor({ output = "Unknown-1", disabled = true })`, three named `hl.workspace_rule` (one with `gaps_out = 4`), `hl.device` (scroll_method/scroll_button), `hl.config({ general = { gaps_out = {…} } })` overscan tweak, `hyprland.start` handler disabling HDMI-A-1.

4. **Lua string escaping in generated code**: Nix `''` strings emit backslashes literally, so regex fields are written verbatim (no `\.` in current patterns — safe); commands contain no double quotes; verify rendered output with a syntax check.

## Verification

1. **Render check**: evaluate home-manager config for axiom and inspect the rendered `hyprland.lua` + generated `*.lua` in the store (or `nix eval` with `--raw` on each `home.file` text). Confirm required files exist and no `.conf` remains under `~/.config/hypr` except `hypridle.conf`.
2. **Syntax check**: run `luac -p` (via `lua`/`luajit` package) over each rendered `.lua` file.
3. **Build**: `nixos-rebuild build --flake .#axiom` (or host under test) on Axiom; no Acorn builds.
4. **Live deploy (post-merge)**: switch axiom, then `hyprctl reload`; confirm: no deprecation warning in the Hyprland log, `hey hook startup` ran (systemd `hyprland-session.target` active), binds respond, workspaces/monitors laid out as before. Record evidence; if a file errors, fix and re-reload (config is hot-reloadable; no session restart required).

## Rollback

- Per-file failure at deploy: `hyprctl reload` re-reads on save; restoring the failing file's previous content and re-reloading returns the session to working state without logout.
- Whole-change rollback: revert the merge commit and rebuild+switch; home-manager regenerates the `.conf` layout on activation. Hyprland 0.56 still parses `.conf`, so the previous state is fully restorable until 0.57.
- Deploy ordering: build → switch → `hyprctl reload config-only` → verify log; never switch while unverified generated Lua has syntax errors (gate in step 2).

## Open Questions

- Exact warning text/severity on 0.56.2 — captured from user report; will confirm from Hyprland log during live deploy.
- Whether `hyprctl reload config-only` remains the correct command on 0.56+ (wiki states `hyprctl reload` works; `config-only` kept if accepted, else dropped to plain `reload`).
