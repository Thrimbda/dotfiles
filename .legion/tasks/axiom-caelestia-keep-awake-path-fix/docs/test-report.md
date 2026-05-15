# Test Report: Axiom Caelestia Keep Awake Path Fix

## Verdict

PASS

## Environment

- Worktree: `.worktrees/axiom-caelestia-keep-awake-path-fix/`
- Branch: `legion/axiom-caelestia-keep-awake-path-fix`
- Base: `origin/master` at `c605bfac`
- Date: 2026-05-15

## Runtime Diagnosis Evidence

Command:

```sh
XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus systemctl --user status axiom-caelestia-keep-awake.service caelestia-shell.service hyprland-session.target --no-pager
```

Relevant result:

```text
axiom-caelestia-keep-awake.service: Failed with result 'exit-code'.
FileNotFoundError: [Errno 2] No such file or directory: 'caelestia-shell'
caelestia-shell.service: active (running)
hyprland-session.target: active
```

Why chosen: this proved the regression was not missing deployment or a stopped shell; the default-enable helper failed because its subprocess environment could not resolve `caelestia-shell`.

## Current-Session Mitigation

Command shape used to restore the live session state:

```sh
<evaluated-caelestia-shell>/bin/caelestia-shell ipc call idleInhibitor enable
<evaluated-caelestia-shell>/bin/caelestia-shell ipc call idleInhibitor isEnabled
```

Result:

```text
true
```

Why chosen: this verified the running Caelestia shell IPC works when called through the evaluated binary with the active display environment.

## Targeted Nix Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; names = builtins.attrNames cfg.systemd.user.services; service = cfg.systemd.user.services.axiom-caelestia-keep-awake; helperText = builtins.readFile service.serviceConfig.ExecStart; packageNames = map (p: p.name or "") cfg.users.users.c1.packages; in { hasKeepAwakeService = lib.elem "axiom-caelestia-keep-awake" names; serviceWantedByHyprland = lib.elem "hyprland-session.target" service.wantedBy; serviceWantsCaelestia = lib.elem "caelestia-shell.service" service.wants; serviceAfterCaelestia = lib.elem "caelestia-shell.service" service.after; helperUsesDirectShell = lib.hasInfix "/bin/caelestia-shell ipc call idleInhibitor enable" helperText; helperAvoidsCliPathDependency = !(lib.hasInfix "/bin/caelestia shell idleInhibitor enable" helperText); noAxiomSleepModeService = !(lib.elem "axiom-sleep-mode-apply" names) && !(lib.elem "axiom-no-sleep-inhibit" names); noAxiomSleepModePackage = !(lib.any (n: n == "axiom-sleep-mode") packageNames); }'
```

Result:

```json
{"hasKeepAwakeService":true,"helperAvoidsCliPathDependency":true,"helperUsesDirectShell":true,"noAxiomSleepModePackage":true,"noAxiomSleepModeService":true,"serviceAfterCaelestia":true,"serviceWantedByHyprland":true,"serviceWantsCaelestia":true}
```

Why chosen: this directly proves the service remains wired to the intended session targets while the helper no longer depends on the Caelestia Python CLI's `PATH` lookup for `caelestia-shell`.

## Diff Check

Command:

```sh
git diff --check
```

Result: PASS with no output.

## Axiom Toplevel Build

Command:

```sh
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Relevant build evidence:

- Built `axiom-caelestia-keep-awake.drv`.
- Built `unit-axiom-caelestia-keep-awake.service.drv`.
- Built `nixos-system-axiom-25.11.20260203.e576e3c.drv`.

Warnings observed: existing nixpkgs/specialArgs and deprecated option/package warnings remained present and are unrelated to this task.

## Skipped Live Checks

No reboot or new-login smoke was run after changing the repository because the fix still needs deployment. Post-deploy smoke should run:

```sh
systemctl --user reset-failed axiom-caelestia-keep-awake.service
systemctl --user restart axiom-caelestia-keep-awake.service
caelestia shell idleInhibitor isEnabled
```

Expected result: the service exits successfully and `isEnabled` reports enabled in the graphical session.
