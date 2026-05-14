# Test Report: Axiom No-Sleep Power Mode

## Verdict

PASS

## Environment

- Worktree: `.worktrees/axiom-no-sleep-power-mode/`
- Branch: `legion/axiom-no-sleep-power-mode-default-toggle`
- Base: `origin/master` at `5173a318`
- Date: 2026-05-14

## Commands

### Targeted Nix Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; hypridle = cfg.home.configFile."hypr/hypridle.conf".text; globalHypridle = builtins.readFile ./config/hypr/hypridle.conf; inhibit = cfg.systemd.user.services.axiom-no-sleep-inhibit.serviceConfig.ExecStart; apply = cfg.systemd.user.services.axiom-sleep-mode-apply; packageNames = map (p: p.name or "") cfg.users.users.c1.packages; launcherCount = builtins.length (lib.filter (n: lib.hasPrefix "launcher-" n) packageNames); in { generatedHypridleUsesModeScript = lib.hasInfix "axiom-sleep-mode maybe-suspend" hypridle; generatedHypridleAvoidsDirectSuspend = !(lib.hasInfix "systemctl suspend || loginctl suspend" hypridle); globalHypridleStillDirectSuspend = lib.hasInfix "systemctl suspend || loginctl suspend" globalHypridle; globalHypridleNotAxiomSpecific = !(lib.hasInfix "axiom-sleep-mode" globalHypridle); inhibitorBlocksSleep = lib.hasInfix "systemd-inhibit --what=sleep --mode=block" inhibit; inhibitorUsesSleepInfinity = lib.hasInfix "sleep infinity" inhibit; applyWantedByHyprland = lib.elem "hyprland-session.target" apply.wantedBy; applyRunsModeScript = lib.hasInfix "axiom-sleep-mode apply" apply.serviceConfig.ExecStart; hasModeScriptPackage = lib.any (n: n == "axiom-sleep-mode") packageNames; launcherPackageCountAtLeastFour = launcherCount >= 4; }'
```

Result:

```json
{"applyRunsModeScript":true,"applyWantedByHyprland":true,"generatedHypridleAvoidsDirectSuspend":true,"generatedHypridleUsesModeScript":true,"globalHypridleNotAxiomSpecific":true,"globalHypridleStillDirectSuspend":true,"hasModeScriptPackage":true,"inhibitorBlocksSleep":true,"inhibitorUsesSleepInfinity":true,"launcherPackageCountAtLeastFour":true}
```

Why chosen: this directly validates the changed claims without triggering power actions. It proves Axiom receives the generated Hypridle override, the global Hypridle source remains unchanged for other hosts, the no-sleep inhibitor blocks sleep, the apply service starts with the Hyprland session, and the user package set includes the mode script plus launcher packages.

### Diff Check

Command:

```sh
git diff --check
```

Result: PASS with no output.

Why chosen: catches whitespace errors across production and Legion evidence changes.

### Axiom Toplevel Build

Command:

```sh
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Relevant build evidence:

- Built `hm_.confighyprhypridle.conf.drv` for the generated Axiom Hypridle override.
- Built `axiom-sleep-mode.drv`.
- Built three new launcher derivations.
- Built `unit-axiom-sleep-mode-apply.service.drv`.
- Built `unit-axiom-no-sleep-inhibit.service.drv`.
- Built `nixos-system-axiom-25.11.20260203.e576e3c.drv`.

Warnings observed: existing nixpkgs/specialArgs and deprecated option/package warnings unrelated to this task remained present.

Why chosen: this is the strongest local validation that the Axiom configuration evaluates and builds with the new script, launcher entries, user services, and generated Hypridle file.

## Skipped Live Checks

No live suspend, hibernate, reboot, or long idle test was run from this tool session. These checks are disruptive and require the switched Axiom graphical session.

Post-deploy smoke should verify:

- `axiom-sleep-mode status` reports the expected mode and inhibitor state.
- Desktop launcher entries can switch no-sleep and allow-sleep.
- `systemd-inhibit --list` shows the Axiom inhibitor while no-sleep mode is active.
- Idle still locks and turns DPMS off.
- Idle does not suspend in no-sleep mode.
- Allow-sleep mode permits the existing suspend behavior when deliberately selected.

## Post-Rebase Validation

After rebasing onto the latest `origin/master`, conflicts were resolved in `hosts/axiom/default.nix` and `.legion/wiki/log.md`. The resolution preserved upstream Axiom Fcitx theme changes and this task's no-sleep power-mode implementation.

Commands rerun after the rebase:

```sh
nix eval --impure --json --expr '... fcitxThemeKept = cfg.modules.desktop.input.fcitx5.theme.name == "FluentDark"; ...'
git diff --check
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Targeted assertion result included all original booleans as `true` plus `fcitxThemeKept=true`. The post-rebase Axiom toplevel build also passed.
