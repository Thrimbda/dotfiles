# Report Walkthrough: Hyprland Config Format Migration

- Task: `dotfiles-hyprland-lua-migration`
- Mode: **implementation**
- Commit: `5a760f7e` · Branch: `legion/dotfiles-hyprland-lua-migration-hyprland-lua`

## What changed

Hyprland 0.55 deprecated hyprlang config; 0.56.1 warns that `.conf` will be removed in 0.57. This change migrates the repo's generated Hyprland config from hyprlang `.conf` to the `hl.*` Lua API.

- `config/hypr/hyprland.conf` → `config/hypr/hyprland.lua`: requires `custom/env`, `custom/execs`, `custom/general`, `custom/rules`, `custom/keybinds`, `workspaces`, `monitors` in the old source order.
- `modules/desktop/hyprland.nix` now generates `.lua` files: `hl.env`, `hl.on("hyprland.start")` + `hl.exec_cmd` (replaces `exec-once`), `hl.window_rule`/`hl.layer_rule`, `hl.bind` with locked/release/mouse flags, `hl.config` blocks (ecosystem/input/xwayland/cursor), `hl.workspace_rule`, `hl.monitor`.
- `custom/variables.conf` deleted; Nix-computed values are inlined into the generated Lua.
- `extraConfig` now carries Lua; converted axiom (render/misc/cursor guards), azar + udon (Unknown-1 disable + named workspaces; udon adds `hl.device` scroll config, overscan gaps, HDMI-A-1 startup disable), ramen (special workspaces, lid switch binds), and the autumnal theme (cursor env, general/decoration, caelestia layer polish).
- `hypridle.conf` untouched — hypridle is unaffected by Hyprland's config format removal.

## Verification evidence

See `.legion/tasks/dotfiles-hyprland-lua-migration/docs/test-report.md`:

- `nix-instantiate --parse` on all touched Nix files — PASS.
- Rendered every generated `.lua` for axiom/azar/ramen/udon via `nix eval --raw` — content matches the RFC mapping.
- `luac -p` on all 12 rendered files + root `hyprland.lua` — PASS.
- `nixos-rebuild build --flake .#axiom` — PASS; built `home-manager-files` shows only `hypridle.conf`/`xdph.conf` remaining as `.conf`, all others `.lua`.

Design gate: `.legion/tasks/dotfiles-hyprland-lua-migration/docs/rfc.md` + `docs/review-rfc.md` (PASS). Change review: `docs/review-change.md` (PASS).

## Residual manual checks (post-merge deploy, documented in test-report)

1. `hey reload` on axiom; confirm the deprecation warning is gone from the Hyprland log.
2. Confirm `hey hook startup` still runs first and `hyprland-session.target` is active.
3. Spot-check binds: fullscreen toggle, mouse drag/resize, workspace 1..20.
4. Confirm home-manager activation pruned the obsolete managed `.conf` symlinks.
5. If `hyprctl reload config-only` is rejected on 0.56, fall back to plain `hyprctl reload`.

## Rollback

Revert the merge commit and rebuild+switch; Hyprland 0.56 still parses `.conf`, so the previous state is restorable until 0.57.
