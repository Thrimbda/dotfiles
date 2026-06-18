# Test Report: Axiom Hyprland Mouse Workspace Move

## Summary

Result: PASS

本次验证优先证明当前改动的两个核心声明：新增 mouse bindings 确实进入 Axiom 生成的 Hyprland keybind 文本，并且 assembled Hyprland 配置能被当前 Hyprland parser 接受。

## Commands

1. Generated keybind assertion

`nix eval --impure --json '.#nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/keybinds.conf".text' --apply 'text: let flat = builtins.replaceStrings ["\n"] [" "] text; in { move = builtins.match ".*bindm = SUPER, mouse:272, movewindow.*" flat != null; resize = builtins.match ".*bindm = SUPER, mouse:273, resizewindow.*" flat != null; next = builtins.match ".*bind = SUPER\\+SHIFT, mouse_down, movetoworkspace, \\+1.*" flat != null; previous = builtins.match ".*bind = SUPER\\+SHIFT, mouse_up, movetoworkspace, -1.*" flat != null; }'`

Result:

```json
{"move":true,"next":true,"previous":true,"resize":true}
```

2. Diff hygiene

`git diff --check`

Result: PASS, no output.

3. Hyprland parser validation

`tmpdir=$(mktemp -d ".legion/tasks/axiom-hyprland-mouse-workspace-move/tmp.hypr.XXXXXX") && trap 'rm -rf "$tmpdir"' EXIT && full=$(nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake (toString ./.); c = flake.nixosConfigurations.axiom.config; pkgs = flake.nixosConfigurations.axiom.pkgs; in pkgs.writeText "hyprland-full.conf" (c.home.configFile."hypr/custom/env.conf".text + "\n" + c.home.configFile."hypr/custom/variables.conf".text + "\n" + c.home.configFile."hypr/custom/execs.conf".text + "\n" + c.home.configFile."hypr/custom/general.conf".text + "\n" + c.home.configFile."hypr/custom/rules.conf".text + "\n" + c.home.configFile."hypr/custom/keybinds.conf".text + "\n" + c.home.configFile."hypr/workspaces.conf".text + "\n" + c.home.configFile."hypr/monitors.conf".text)') && hypr=$(nix eval --impure --raw '.#nixosConfigurations.axiom.config.programs.hyprland.package.outPath') && XDG_RUNTIME_DIR="$tmpdir" "$hypr/bin/Hyprland" --verify-config --config "$full"`

Result: PASS. Hyprland returned:

```text
======== Config parsing result:

config ok
```

Hyprland also emitted the expected warning about launching without `start-hyprland`; this does not invalidate parser verification.

## Coverage

- `SUPER + left mouse drag` generated as `bindm = SUPER, mouse:272, movewindow`.
- `SUPER + right mouse drag` generated as `bindm = SUPER, mouse:273, resizewindow`.
- `SUPER+SHIFT + wheel down` generated as `movetoworkspace, +1`.
- `SUPER+SHIFT + wheel up` generated as `movetoworkspace, -1`.
- Assembled generated Hyprland config parses successfully with the evaluated Hyprland package.

## Not Covered

- Live physical mouse behavior in the running Axiom Hyprland session was not exercised from this non-session environment.
- Caelestia layer-shell event interception over its own UI surfaces remains expected behavior and was not changed.
