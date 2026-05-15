# Axiom Hyprland DPMS Safe Mode Fix - Test Report

## Summary

PASS. Focused static/Nix validation confirms Axiom now generates a Hyprland config with `render.cm_enabled = false`, `hypridle.service` has the required command PATH entries, the assembled Hyprland config parses, and the Axiom NixOS toplevel builds.

## Commands

1. Focused generated-config eval

   Command:

   ```sh
   nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; general = cfg.home.configFile."hypr/custom/general.conf".text; pathNames = map (p: p.name or "") cfg.systemd.user.services.hypridle.path; in { cmDisabled = lib.hasInfix "cm_enabled = false" general; renderBlockPresent = lib.hasInfix "render {" general; hasHyprland = lib.any (n: lib.hasInfix "hyprland" n) pathNames; hasHyprlock = lib.any (n: lib.hasInfix "hyprlock" n) pathNames; hasProcps = lib.any (n: lib.hasInfix "procps" n) pathNames; hasSystemd = lib.any (n: lib.hasInfix "systemd" n) pathNames; hypridlePath = pathNames; }'
   ```

   Result: PASS.

   Evidence:

   ```json
   {
     "cmDisabled": true,
     "renderBlockPresent": true,
     "hasHyprland": true,
     "hasHyprlock": true,
     "hasProcps": true,
     "hasSystemd": true,
     "hypridlePath": [
       "hyprland-0.53.3",
       "hyprlock-0.9.2",
       "procps-4.0.4",
       "systemd-258.2",
       "coreutils-9.8",
       "findutils-4.10.0",
       "gnugrep-3.12",
       "gnused-4.9",
       "systemd-258.2"
     ]
   }
   ```

2. Diff hygiene

   Command:

   ```sh
   git diff --check
   ```

   Result: PASS. No whitespace errors or conflict markers were reported.

3. Axiom toplevel build

   Command:

   ```sh
   nix build --no-link ".#nixosConfigurations.axiom.config.system.build.toplevel"
   ```

   Result: PASS. The toplevel build completed. Nix emitted existing evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, and renamed `hardware.pulseaudio`; none are introduced by this task.

4. Assembled Hyprland parser validation

   Command:

   ```sh
   runtime_dir=".legion/tasks/axiom-hyprland-dpms-safe-mode-fix/runtime" && mkdir -p "$runtime_dir" && full=$(nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake (toString ./.); c = flake.nixosConfigurations.axiom.config; pkgs = flake.nixosConfigurations.axiom.pkgs; in pkgs.writeText "hyprland-full.conf" (c.home.configFile."hypr/custom/env.conf".text + "\n" + c.home.configFile."hypr/custom/variables.conf".text + "\n" + c.home.configFile."hypr/custom/execs.conf".text + "\n" + c.home.configFile."hypr/custom/general.conf".text + "\n" + c.home.configFile."hypr/custom/rules.conf".text + "\n" + c.home.configFile."hypr/custom/keybinds.conf".text + "\n" + c.home.configFile."hypr/workspaces.conf".text + "\n" + c.home.configFile."hypr/monitors.conf".text)') && hypr=$(nix eval --impure --raw '.#nixosConfigurations.axiom.config.programs.hyprland.package.outPath') && XDG_RUNTIME_DIR="$PWD/$runtime_dir" "$hypr/bin/Hyprland" --verify-config --config "$full"
   ```

   Result: PASS. Hyprland returned `config ok`. It emitted the expected warning about launching without `start-hyprland`; this is normal for parser-only validation.

## Why These Checks

- The focused eval directly proves the two intended configuration changes without relying on text greps over source files.
- The toplevel build proves the NixOS configuration still realizes after changing host extra config and the user service PATH.
- `Hyprland --verify-config` exercises the actual Hyprland parser for the generated `render` block.

## Not Covered

- Live DPMS/suspend-resume behavior is not proven here. Final proof requires deploying the built generation, restarting the Axiom Hyprland session, triggering DPMS off/on or suspend/resume, and confirming no new Hyprland coredump or `--safe-mode` restart appears.
- The upstream Hyprland bug is not fixed by this task; this is a local mitigation until the pinned Hyprland package includes the upstream fix.
