# Review Change: Hyprland Config Format Migration

- Task: `dotfiles-hyprland-lua-migration`
- Reviewed commit: `5a760f7e` (branch `legion/dotfiles-hyprland-lua-migration-hyprland-lua`)
- Date: 2026-08-19

## Verdict

**PASS**

## Scope compliance

Changed files: `config/hypr/hyprland.conf → hyprland.lua`, `modules/desktop/hyprland.nix`, `modules/themes/autumnal/hyprland.nix`, `hosts/{axiom,azar,ramen,udon}/default.nix`, `.legion/tasks/dotfiles-hyprland-lua-migration/**`.

- All changes fall inside plan.md scope. The udon consumer was found during review and converted (RFC/plan/test-report updated to match); no other hyprlang config remains in the repo (verified with a keyword scan for `monitor =`, `workspace = name:`, `exec-once`, `windowrule`, `layerrule`, `bindl/bindr/bindm =`, `device {` across hosts/modules/config).
- Non-goals intact: `hypridle.conf` and `hypr/xdph.conf` untouched; Caelestia, uwsm env, monitor hotplug scripts, and keybinding help text unchanged.
- `hypridle.enable` gating added by #166 untouched.

## Correctness findings

- Binding semantics: `bindl`→`{locked=true}`, `bindr`→`{release=true}`, `bindm`→`{mouse=true}`, wheel binds without mouse flag — rendered keybinds.lua matches the RFC mapping, including workspace binds 1..10 / 11..20 on the second monitor.
- Workspace rules: rendered workspaces.lua pins 1..10 to DP-4 and 11..20 to DP-5 with default/persistent on 1/11 — identical to the old hyprlang output.
- Rules ordering: autumnal's caelestia `ignore_alpha = 0` is registered in general.lua before rules.lua's `0.79`, preserving the old source order (0.79 wins).
- Monitors: disable → `disabled = true`; advanced fields (bitdepth/cm/sdrbrightness/sdrsaturation) become direct hl.monitor fields; empty-output fallback rule for hosts with default monitor list remains valid.
- All rendered files pass `luac -p` and the axiom closure builds (see docs/test-report.md).

## Maintainability

- `extraConfig` semantics (now Lua) documented in the option comment; generated file headers say what generates them; require order documented at the root hyprland.lua.
- Dropped `custom/variables.conf` — no dangling references (all `$var` usages were in the generated files being replaced).

## Security lens

Security triggers evaluated: none (no auth/secrets/trust-boundary change). Noted: Lua config can execute arbitrary code at compositor privilege; this repo's config is generated from trusted Nix input, and the wiki explicitly flags this trust model. No action needed beyond what exists.

## Non-blocking suggestions

- `hyprctl reload config-only` acceptance on 0.56 is an open question; if rejected at deploy, fall back to plain `hyprctl reload` (already recorded in rfc.md Open Questions and test-report residual list).
- Post-merge deploy should confirm home-manager activation removes the obsolete managed `.conf` symlinks.

## Residual (deferred to deploy, not blocking delivery)

- Live axiom session: warning-free reload, startup hook ordering, keybind spot checks — see docs/test-report.md "Skipped / residual".
