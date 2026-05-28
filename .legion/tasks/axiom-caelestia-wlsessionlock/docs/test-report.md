# Test Report

## Summary

Result: PASS for static and build-time validation.

Live Hyprland lock/unlock behavior is not proven in this headless/tool session and remains a post-deploy smoke check.

## Commands

### Script Syntax

```sh
zsh -n config/hypr/bin/lock.zsh config/hypr/hooks/idle.zsh
```

Result: PASS.

### Generated Keybinds

```sh
nix eval --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/keybinds.conf".text'
```

Result: PASS. The generated `SUPER+SHIFT+L` binding executes the evaluated Caelestia CLI path with `shell lock lock`.

### Hypridle Service PATH

```sh
nix eval --json '.#nixosConfigurations.axiom.config.systemd.user.services.hypridle.path'
```

Result: PASS. The evaluated service path includes Hyprland, `caelestia-cli`, and `caelestia-shell`.

### Axiom Toplevel Eval

```sh
nix eval --raw '.#nixosConfigurations.axiom.config.system.build.toplevel.drvPath'
```

Result: PASS.

### Axiom Toplevel Build

```sh
nix build '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link
```

Result: PASS.

### Hyprlock Closure Absence

```sh
out="$(nix build '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link --print-out-paths)" && if nix path-info -r "$out" | rg 'hyprlock'; then exit 1; else exit 0; fi
```

Result: PASS. No `hyprlock` path was found in the evaluated Axiom system closure.

### Hyprlock PAM Absence

```sh
nix eval --impure --expr 'let c = (builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-caelestia-wlsessionlock").nixosConfigurations.axiom.config; in builtins.hasAttr "hyprlock" c.security.pam.services'
```

Result: PASS. Output was `false`.

### Active Reference Search

```sh
if rg 'hyprlock' flake.nix modules config hosts --glob '*.nix' --glob '*.conf' --glob '*.zsh' --glob '*.sh' --glob '*.org'; then exit 1; else exit 0; fi
```

Result: PASS. No active host/module/config references remain outside historical Legion task/wiki text.

### Whitespace

```sh
git diff --check
```

Result: PASS.

## Residual Risk

- Actual WlSessionLock rendering, keyboard focus, PAM unlock, and Hypridle-triggered lock timing require a live Axiom Hyprland/Caelestia session.
- If Caelestia IPC is unavailable when Hypridle fires, there is intentionally no Hyprlock fallback.
