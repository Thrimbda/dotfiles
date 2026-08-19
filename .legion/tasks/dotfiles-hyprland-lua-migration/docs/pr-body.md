## Summary

Hyprland 0.55+ deprecated the hyprlang config format and 0.57 will remove it. This PR migrates the generated Hyprland configuration from `.conf` to the Lua `hl.*` API so the deprecation warning disappears and the desktop survives the 0.57 release.

- `hyprland.conf` → `hyprland.lua` (requires the generated modules in the old source order)
- `modules/desktop/hyprland.nix` generates `custom/{env,execs,general,rules,keybinds}.lua`, `workspaces.lua`, `monitors.lua`
- `extraConfig` now carries Lua; axiom/azar/ramen/udon hosts and the autumnal theme converted
- `custom/variables.conf` removed (values inlined from Nix)
- `hypridle.conf` untouched (hypridle is unaffected)

## Files

- `config/hypr/hyprland.conf` → `config/hypr/hyprland.lua`
- `modules/desktop/hyprland.nix`
- `modules/themes/autumnal/hyprland.nix`
- `hosts/axiom/default.nix`, `hosts/azar/default.nix`, `hosts/ramen/default.nix`, `hosts/udon/default.nix`

## Verification

- `nix-instantiate --parse` on all touched Nix files: OK
- Rendered all generated Lua for axiom/azar/ramen/udon and passed `luac -p`
- `nixos-rebuild build --flake .#axiom`: builds; store layout shows no `.conf` left except `hypridle.conf` and `xdph.conf` (both intentional)
- Full evidence: `.legion/tasks/dotfiles-hyprland-lua-migration/docs/{rfc,review-rfc,test-report,review-change}.md`

## Behavior notes

- Same binds, same rules, same workspace layout, same startup order. Binds use `locked`/`release`/`mouse` flags for the old bindl/bindr/bindm semantics.
- `$var` indirection is gone; values are inlined by Nix.

## Deploy plan (after merge)

1. `nixos-rebuild switch --flake .#axiom` (builds on Axiom)
2. `hey reload` → confirm no `.conf` deprecation warning in the Hyprland log and `hyprland-session.target` active
3. Spot-check binds (fullscreen, mouse drag/resize, workspace 1..20)

## Rollback

Revert merge + rebuild/switch; Hyprland 0.56 still parses `.conf` until 0.57.
