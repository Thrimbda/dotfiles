# Test Report: Hyprland Config Format Migration

- Task: `dotfiles-hyprland-lua-migration`
- Date: 2026-08-19
- Branch: `legion/dotfiles-hyprland-lua-migration-hyprland-lua` (worktree `.worktrees/dotfiles-hyprland-lua-migration`)

## Claim under test

The repo generates a fully Lua-based Hyprland config (`hyprland.lua` + required `*.lua` modules) that replaces the deprecated hyprlang `.conf` layout, builds cleanly for axiom, and keeps azar/ramen `extraConfig` contributions valid Lua.

## Chosen validation path and why

1. `nix-instantiate --parse` on each touched `.nix` file — cheapest syntax gate, proves the Nix edits are well-formed.
2. `nix eval --raw` of `home.file."…hypr/*.lua".text` for axiom/azar/ramen — renders the exact strings Nix will install, without needing a full build for each host.
3. `luac -p` on every rendered `.lua` file plus the repo's root `hyprland.lua` — proves Lua syntax validity (Hyprland embeds Lua; a syntax error would kill config load for that file).
4. `nixos-rebuild build --flake .#axiom` — proves the full NixOS + home-manager closure builds, and the store output is inspected to confirm the final file layout.

Live-session checks (warning gone, binds work, startup hook ordering) are residual deploy checks recorded for the post-merge deployment, because running a nested compositor session or switching the active desktop mid-review is out of scope for this stage.

## Commands executed

```sh
nix-instantiate --parse modules/desktop/hyprland.nix modules/themes/autumnal/hyprland.nix \
  hosts/axiom/default.nix hosts/azar/default.nix hosts/ramen/default.nix   # all OK

nix eval --raw '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/env.lua".text' > env.lua   # + execs/general/rules/keybinds/workspaces/monitors
nix eval --raw '.#nixosConfigurations.azar.config.home-manager.users.c1.home.file.".config/hypr/custom/general.lua".text' > general-azar.lua
nix eval --raw '.#nixosConfigurations.ramen.config.home-manager.users.hlissner.home.file.".config/hypr/custom/general.lua".text' > general-ramen.lua

nix shell nixpkgs#lua -c sh -c 'for f in hypr-rendered/*.lua config/hypr/hyprland.lua; do luac -p "$f" || exit 1; done'   # all 11 files OK

nixos-rebuild build --flake .#axiom --use-substitutes -L    # Done
```

## Results

| Check | Result |
|---|---|
| nix parse (5 files) | PASS |
| axiom rendered env/execs/general/rules/keybinds/workspaces/monitors | PASS, content matches RFC mapping |
| azar rendered general.lua (Unknown-1 disable + named workspaces) | PASS, `luac -p` OK |
| ramen rendered general.lua (special workspaces + lid switch binds) | PASS, `luac -p` OK |
| udon rendered general.lua (named workspaces + hl.device scroll + overscan gaps + HDMI-A-1 disable) | PASS, `luac -p` OK |
| root `config/hypr/hyprland.lua` (7 requires, order env→execs→general→rules→keybinds→workspaces→monitors) | PASS, `luac -p` OK |
| axiom closure build | PASS: `nixos-system-axiom-26.05.7813.0dd31db7e6db` |
| built `home-manager-files` layout | `.config/hypr/` contains `hyprland.lua`, `custom/{env,execs,general,keybinds,rules}.lua`, `monitors.lua`, `workspaces.lua`; no `*.conf` except `hypridle.conf` (intended) and `xdph.conf` (out of scope, unchanged) |

## Failures

None.

## Skipped / residual (recorded for post-merge deploy)

- Live `hyprctl reload` on axiom: confirm no `.conf` deprecation warning in the Hyprland log.
- `hey hook startup` still runs first (systemd `hyprland-session.target` active after reload/restart).
- Keybind spot checks (fullscreen toggle `mode/action` mapping, mouse drag/resize, workspace binds 1..20).
- Home-manager activation cleanup of the now-obsolete managed `.conf` symlinks (`custom/*.conf`, `monitors.conf`, `workspaces.conf`, `hyprland.conf`).
- `hyprctl reload config-only` acceptance on 0.56 (fallback to plain `hyprctl reload` if rejected).
