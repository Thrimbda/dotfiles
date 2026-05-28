# Test Report - Axiom Caelestia Idle Timeouts

## Summary

Result: PASS.

The change aligns Caelestia's own idle policy with Axiom Hypridle at 900 seconds for lock and 1800 seconds for DPMS, removes Caelestia's upstream 600 second automatic sleep action from Axiom settings, preserves the checked-in Hypridle policy, and keeps the Axiom NixOS configuration buildable.

## Commands

### Diff Whitespace

Command:

```sh
git diff --check
```

Result: PASS. No whitespace errors were reported.

Why chosen: this is the lowest-cost guard against malformed patch whitespace before deeper Nix validation.

### Targeted Nix Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; idle = cfg.modules.desktop.caelestia.settings.general.idle; preStart = builtins.head cfg.modules.desktop.caelestia.session.preStart; helperText = builtins.readFile preStart; hypridle = builtins.readFile ./config/hypr/hypridle.conf; lib = flake.lib; in { lockTimeout = builtins.elem { timeout = 900; idleAction = "lock"; } idle.timeouts; dpmsTimeout = builtins.elem { timeout = 1800; idleAction = "dpms off"; returnAction = "dpms on"; } idle.timeouts; onlyTwoCaelestiaTimeouts = builtins.length idle.timeouts == 2; noCaelestiaSleep = !(lib.hasInfix "suspend" (builtins.toJSON idle) || lib.hasInfix "hibernate" (builtins.toJSON idle) || lib.hasInfix "600" (builtins.toJSON idle)); helperMigratesIdle = lib.hasInfix ".general.idle = $idle" helperText; helperUsesArgjson = lib.hasInfix "--argjson idle" helperText; hypridleLock900 = lib.hasInfix "timeout = 900 # 15mins" hypridle; hypridleDpms1800 = lib.hasInfix "timeout = 1800 # 30mins" hypridle; hypridleNoSuspend = !(lib.hasInfix "suspend" hypridle || lib.hasInfix "hibernate" hypridle); }'
```

Result: PASS.

Output:

```json
{"dpmsTimeout":true,"helperMigratesIdle":true,"helperUsesArgjson":true,"hypridleDpms1800":true,"hypridleLock900":true,"hypridleNoSuspend":true,"lockTimeout":true,"noCaelestiaSleep":true,"onlyTwoCaelestiaTimeouts":true}
```

Why chosen: this directly proves the generated Axiom Caelestia settings, the pre-start migration helper, and the Hypridle policy values that caused the reported behavior.

### Focused Automatic Sleep Searches

Commands:

```sh
Grep pattern `suspend-then-hibernate|systemctl.*suspend|loginctl.*suspend|timeout = 600|"timeout"[[:space:]]*:[[:space:]]*600` in `hosts/axiom`.
Grep pattern `suspend-then-hibernate|systemctl.*suspend|loginctl.*suspend|timeout = 600|"timeout"[[:space:]]*:[[:space:]]*600` in `config/hypr`.
```

Result: PASS. No active host or Hypridle matches were found.

Why chosen: this confirms the Axiom active config surfaces do not contain the removed 600 second sleep/suspend action.

### Migration Filter Syntax

Command:

```sh
jq -n -e --arg app bytedance-feishu --arg legacy bytedance-feishu.desktop --argjson idle '{"lockBeforeSleep":true,"inhibitWhenAudio":true,"timeouts":[{"timeout":900,"idleAction":"lock"},{"timeout":1800,"idleAction":"dpms off","returnAction":"dpms on"}]}' '{launcher:{favouriteApps:["steam","bytedance-feishu.desktop"]},appearance:{font:{}}} | .general = (.general // {}) | .general.idle = $idle | .launcher = (.launcher // {}) | .launcher.favouriteApps = ((.launcher.favouriteApps // []) as $apps | ($apps | map(select(. != $legacy))) as $normalized | if ($normalized | index($app)) then $normalized else $normalized + [$app] end) | (.general.idle.timeouts | length == 2) and (.launcher.favouriteApps | index($legacy) | not) and (.launcher.favouriteApps | index($app) != null)' >/dev/null
```

Result: PASS.

Why chosen: the Nix checks prove the helper contains the intended migration, while this command proves the jq update shape parses and preserves unrelated settings on a representative shell config object.

### Axiom Toplevel Build

Command:

```sh
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS.

Warnings observed were pre-existing Nix evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `system`, and renamed `hardware.pulseaudio` options. No build failure occurred.

Why chosen: this proves the host-level NixOS configuration still evaluates and realizes generated home/session artifacts after the Caelestia settings and migration change.

## Skipped

- Live idle timing, suspend, and hibernate tests were not run because they would disrupt the active Axiom graphical session.
- Post-deploy smoke should restart the Hyprland/Caelestia session and confirm `~/.config/caelestia/shell.json` contains the 900/1800 `general.idle.timeouts` and no 600 second sleep action.
