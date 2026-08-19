# Verification Report: Axiom Single Idle Owner And Hotplug Recovery

## Result

PASS for static configuration, generated-script, and syntax validation.

The live 30-minute DPMS/wake test is intentionally deferred because it disrupts the active desktop. It remains required after deployment.

## Commands And Evidence

### Axiom policy and default-host regression

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); axiom = flake.nixosConfigurations.axiom.config; ramen = flake.nixosConfigurations.ramen.config; lib = flake.lib; watcher = builtins.readFile axiom.systemd.user.services.hyprland-monitor-hotplug.serviceConfig.ExecStart; timeouts = axiom.modules.desktop.caelestia.settings.general.idle.timeouts; in { axiomHypridleDisabled = !axiom.modules.desktop.hyprland.hypridle.enable; axiomHypridleUnitAbsent = !(builtins.hasAttr "hypridle" axiom.systemd.user.services); ramenHypridleDefaultEnabled = ramen.modules.desktop.hyprland.hypridle.enable; ramenHypridleUnitPresent = builtins.hasAttr "hypridle" ramen.systemd.user.services; caelestiaLockTimeout = (builtins.elemAt timeouts 0).timeout == 900 && (builtins.elemAt timeouts 0).idleAction == "lock"; caelestiaDpmsTimeout = (builtins.elemAt timeouts 1).timeout == 1800 && (builtins.elemAt timeouts 1).idleAction == "dpms off" && (builtins.elemAt timeouts 1).returnAction == "dpms on"; noCaelestiaSleepAction = lib.all (entry: !(lib.hasInfix "sleep" (entry.idleAction or ""))) timeouts; watcherUsesInstances = lib.hasInfix "instances -j" watcher; watcherMatchesDisplayThenFallsBack = lib.hasInfix "if ($matching | length) > 0 then $matching else $instances end" watcher; watcherUsesPipefail = lib.hasInfix "set -euo pipefail" watcher; watcherBacksOffAfterAnyStreamExit = lib.hasInfix "done; then\n    :\n  fi\n  # A compositor restart invalidates socket2; rediscover it after a bounded delay.\n  " watcher && lib.hasInfix "/sleep 2\n" watcher; }'
```

Result:

```json
{
  "axiomHypridleDisabled": true,
  "axiomHypridleUnitAbsent": true,
  "caelestiaDpmsTimeout": true,
  "caelestiaLockTimeout": true,
  "noCaelestiaSleepAction": true,
  "ramenHypridleDefaultEnabled": true,
  "ramenHypridleUnitPresent": true,
  "watcherBacksOffAfterAnyStreamExit": true,
  "watcherMatchesDisplayThenFallsBack": true,
  "watcherUsesInstances": true,
  "watcherUsesPipefail": true
}
```

This is the primary check because it asserts the rendered Nix configuration rather than only searching source text. It proves Axiom has no generated Hypridle unit, preserves Caelestia's 900/1800 lock/DPMS policy without sleep, does not change the default behavior for Ramen, and adds a bounded delay after every event-stream completion.

### Generated watcher script

```bash
nix build --no-link --impure --expr 'let cfg = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; in cfg.systemd.user.services.hyprland-monitor-hotplug.serviceConfig.ExecStart'
bash -n /nix/store/3wa26qw574d9v5ff3x56axj8vjk62b5k-hyprland-monitor-hotplug
```

Result: both commands exited 0. The realized script contains the configured Hyprland and jq paths, dynamically selects an instance from `hyprctl instances -j`, checks socket2 exists, enables `pipefail`, and waits two seconds after every event-stream completion before rediscovery.

### Current instance-selection expression

```bash
hyprctl instances -j | jq -r --arg wayland_display wayland-1 '. as $instances | [ .[] | select($wayland_display == "" or .wl_socket == $wayland_display) ] as $matching | if ($matching | length) > 0 then $matching else $instances end | if length == 0 then empty else max_by(.time).instance end'
```

Result: returned the active Hyprland instance signature. This establishes that the new selection expression works against the live Axiom runtime without sending any compositor command.

### Diff hygiene

```bash
git diff --check
```

Result: exited 0.

## Deferred Live Evidence

After deployment:

```bash
systemctl --user stop hypridle.service || true
systemctl --user is-active hypridle.service
systemctl --user status hyprland-monitor-hotplug.service
jq '.general.idle' "$HOME/.config/caelestia/shell.json"
```

Then leave the desktop idle through one full 30-minute DPMS interval and wake it. If the issue recurs, collect:

```bash
journalctl --user -b -u hyprland-monitor-hotplug.service --since '-2 hours'
coredumpctl --no-pager list Hyprland hypridle
```

and the newest `$HOME/.cache/hyprland/hyprlandCrashReport*.txt`.

## Why No Full Toplevel Build

The Axiom configuration was fully evaluated, and the only generated executable modified by this change was realized and syntax-checked. A full toplevel build would add broad closure cost without stronger coverage of the changed idle-owner or socket-recovery behavior. It does not replace the required live DPMS test.
