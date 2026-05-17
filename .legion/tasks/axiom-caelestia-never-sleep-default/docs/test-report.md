# Test Report: Axiom Caelestia Never Sleep Default

## Verdict

PASS

## Environment

- Worktree: `.worktrees/axiom-caelestia-never-sleep-default/`
- Branch: `legion/axiom-caelestia-never-sleep-default-sleep-inhibitor`
- Base: `origin/master` at `a49743c7`
- Date: 2026-05-17

## Targeted Nix Shape Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; startup = cfg.hey.hooks.startup; keepAwakeHook = startup."07-caelestia-keep-awake"; shellHook = startup."06-caelestia-shell"; service = cfg.systemd.user.services.axiom-caelestia-never-sleep; execStart = service.serviceConfig.ExecStart; packageNames = map (p: p.name or "") cfg.users.users.c1.packages; in { shellHookStartsSession = lib.hasInfix "caelestia-session start" shellHook; keepAwakeHookUsesNohup = lib.hasInfix "/bin/nohup" keepAwakeHook; keepAwakeHookBackgrounded = lib.hasInfix "&" keepAwakeHook; neverSleepWantedBySession = service.wantedBy == [ "hyprland-session.target" ]; neverSleepAfterSession = service.after == [ "hyprland-session.target" ]; neverSleepPartOfSession = service.partOf == [ "hyprland-session.target" ]; neverSleepRestarts = service.serviceConfig.Restart == "always"; neverSleepExecStartNamed = lib.hasInfix "axiom-caelestia-never-sleep" execStart; noAxiomSleepModePackage = !(lib.any (n: n == "axiom-sleep-mode") packageNames); }'
```

Result:

```json
{"keepAwakeHookBackgrounded":true,"keepAwakeHookUsesNohup":true,"neverSleepAfterSession":true,"neverSleepExecStartNamed":true,"neverSleepPartOfSession":true,"neverSleepRestarts":true,"neverSleepWantedBySession":true,"noAxiomSleepModePackage":true,"shellHookStartsSession":true}
```

Why chosen: this proves the declarative service shape before building generated store scripts. It verifies the service is session-scoped, restarts if the inhibitor exits, the Keep Awake helper remains backgrounded, and the old `axiom-sleep-mode` package is not back.

## Diff Check

Command:

```sh
git diff --check
```

Result: PASS with no output.

Why chosen: this catches whitespace errors across Nix, Org, and Legion docs before build/PR.

## Axiom Toplevel Build

Command:

```sh
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Relevant build evidence:

- Built `axiom-caelestia-never-sleep.drv`.
- Built `unit-axiom-caelestia-never-sleep.service.drv`.
- Built `nixos-system-axiom-25.11.20260203.e576e3c.drv`.

Warnings observed: existing nixpkgs/specialArgs, deprecated `mesa.drivers`, renamed `system`, and renamed `hardware.pulseaudio` warnings remained present. They are unrelated to this task.

Why chosen: this is the strongest local validation that the Axiom system configuration, generated user unit, and generated script are buildable.

## Built Script Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; startup = cfg.hey.hooks.startup; keepAwakeHook = startup."07-caelestia-keep-awake"; helperPath = builtins.elemAt (builtins.match ".*nohup ([^ ]+).*" keepAwakeHook) 0; helperText = builtins.readFile helperPath; service = cfg.systemd.user.services.axiom-caelestia-never-sleep; inhibitorText = builtins.readFile service.serviceConfig.ExecStart; packageNames = map (p: p.name or "") cfg.users.users.c1.packages; in { keepAwakeHookUsesNohup = lib.hasInfix "/bin/nohup" keepAwakeHook; keepAwakeHookBackgrounded = lib.hasInfix "&" keepAwakeHook; helperUsesDirectShell = lib.hasInfix "/bin/caelestia-shell ipc call idleInhibitor enable" helperText; helperRetriesSixtySeconds = lib.hasInfix "seq 1 120" helperText; neverSleepWantedBySession = service.wantedBy == [ "hyprland-session.target" ]; neverSleepPartOfSession = service.partOf == [ "hyprland-session.target" ]; neverSleepUsesSystemdInhibit = lib.hasInfix "/bin/systemd-inhibit" inhibitorText; neverSleepBlocksSleep = lib.hasInfix "--what=sleep" inhibitorText; neverSleepModeBlock = lib.hasInfix "--mode=block" inhibitorText; neverSleepUsesTail = lib.hasInfix "/bin/tail -f /dev/null" inhibitorText; noAxiomSleepModePackage = !(lib.any (n: n == "axiom-sleep-mode") packageNames); }'
```

Result:

```json
{"helperRetriesSixtySeconds":true,"helperUsesDirectShell":true,"keepAwakeHookBackgrounded":true,"keepAwakeHookUsesNohup":true,"neverSleepBlocksSleep":true,"neverSleepModeBlock":true,"neverSleepPartOfSession":true,"neverSleepUsesSystemdInhibit":true,"neverSleepUsesTail":true,"neverSleepWantedBySession":true,"noAxiomSleepModePackage":true}
```

Why chosen: after the toplevel build realizes generated script paths, this proves the exact Keep Awake and never-sleep script contents: Caelestia IPC is still enabled with the existing retry window, and the new script uses `systemd-inhibit --what=sleep --mode=block` with a long-running `tail -f /dev/null` child.

## Skipped Live Checks

No live suspend, reboot, or long-idle test was run from this tooling session because those checks are disruptive. Post-deploy smoke should run in the real Axiom graphical session:

```sh
caelestia shell idleInhibitor isEnabled
systemctl --user status axiom-caelestia-never-sleep.service
systemd-inhibit --list | grep -i 'Axiom Caelestia'
```

Expected result: Caelestia reports Keep Awake enabled, the user service is active, and `systemd-inhibit --list` shows the Axiom Caelestia sleep blocker.
