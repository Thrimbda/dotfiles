# Axiom Remove Never Sleep - Test Report

## Summary

Result: PASS

The change removes the active Axiom never-sleep service/script, preserves Caelestia Keep Awake enablement, preserves the user's longer Hypridle timing change, and keeps the Axiom NixOS configuration buildable.

## Environment

- Worktree: `.worktrees/axiom-remove-never-sleep/`
- Branch: `legion/axiom-remove-never-sleep-remove-inhibitor`
- Base: `origin/master`
- Date: 2026-05-27

## Validation Commands

### Active Reference Search

Chosen because the task specifically removes active definition, implementation, and usage of the service while allowing historical Legion raw evidence to remain.

```sh
! rg -n 'axiom-caelestia-never-sleep|caelestiaNeverSleep|Axiom Caelestia session defaults to never sleep' hosts/axiom config/hypr .legion/wiki/decisions.md .legion/wiki/patterns.md .legion/wiki/maintenance.md
```

Result: PASS. No active host config, Hypridle config, README, or current-truth wiki file still references the removed service/script.

### Hypridle Timeout Search

Chosen because the user had already changed idle timing in the main workspace and the delivered worktree must preserve that intent.

```sh
rg -n 'timeout = 900 # 15mins|timeout = 1800 # 30mins' config/hypr/hypridle.conf
```

Output:

```text
11:    timeout = 900 # 15mins
16:    timeout = 1800 # 30mins
```

Result: PASS. Lock is 15 minutes and DPMS off is 30 minutes, with comments matching the configured seconds.

### Diff Whitespace Check

Chosen because the change edits Nix, Org, Markdown, and Hypridle config files.

```sh
git diff --check
```

Result: PASS. No whitespace errors were reported.

### Targeted Nix Shape Evaluation

Chosen because it directly validates the Nix-evaluated Axiom policy after removing the declarative service.

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; hypridle = builtins.readFile ./config/hypr/hypridle.conf; startup = cfg.hey.hooks.startup; keepAwakeHook = startup."07-caelestia-keep-awake"; helperPath = builtins.elemAt (builtins.match ".*nohup ([^ ]+).*" keepAwakeHook) 0; helperText = builtins.readFile helperPath; in { noNeverSleepService = !(builtins.hasAttr "axiom-caelestia-never-sleep" cfg.systemd.user.services); hypridleLock900 = lib.hasInfix "timeout = 900 # 15mins" hypridle; hypridleDpms1800 = lib.hasInfix "timeout = 1800 # 30mins" hypridle; noSuspendCommand = !(lib.hasInfix "$suspend_cmd" hypridle || lib.hasInfix "systemctl suspend" hypridle || lib.hasInfix "loginctl suspend" hypridle); keepAwakePreserved = lib.hasInfix "idleInhibitor enable" helperText; }'
```

Output:

```json
{"hypridleDpms1800":true,"hypridleLock900":true,"keepAwakePreserved":true,"noNeverSleepService":true,"noSuspendCommand":true}
```

Result: PASS. The evaluated Axiom config has no `axiom-caelestia-never-sleep` user service, keeps the 15/30 minute Hypridle values, has no suspend command in Hypridle, and still preserves the Caelestia `idleInhibitor enable` helper.

Note: an earlier version of this eval checked the startup hook wrapper text instead of the generated helper text and returned `keepAwakePreserved = false`; rerunning against the generated helper text produced the passing result above.

### Axiom Toplevel Build

Chosen because it is the strongest available headless integration check for the host-local NixOS change.

```sh
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS. The Axiom NixOS toplevel built successfully. Evaluation emitted existing warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `system`, and `hardware.pulseaudio`; none were introduced by this task.

## Not Run

- Live Hyprland/Caelestia smoke was not run from this headless tool session. Post-deploy, start a new Axiom graphical session and confirm `caelestia shell idleInhibitor isEnabled`, Hypridle's active config/logs, and absence of a repository-owned sleep-inhibitor user service.
