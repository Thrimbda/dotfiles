# Test Report: Axiom Caelestia Keep Awake Race Fix

## Verdict

PASS

## Environment

- Worktree: `.worktrees/axiom-caelestia-keep-awake-race-fix/`
- Branch: `legion/axiom-caelestia-keep-awake-race-fix`
- Base: `origin/master` at `e7a43061`
- Date: 2026-05-15

## Runtime Diagnosis Evidence

Commands:

```sh
caelestia-shell list --all
systemctl --user status hyprland-session.target
nix eval --impure --json --expr '... cfg.hey.hooks.startup ...'
```

Relevant results:

```text
hyprland-session.target active since 2026-05-15 19:39:42
Caelestia instance launch time: 2026-05-15 19:39:53
06-caelestia-shell: caelestia-session start
07-caelestia-keep-awake: axiom-caelestia-keep-awake || true
```

Why chosen: this proves the remaining failure is a cold-start race. `caelestia-session start` backgrounds the runner, the shell IPC instance can register after the next hook starts, and the previous 10-second helper window was too short for the observed 11-second registration.

## Manual Helper Smoke

Command shape:

```sh
<caelestia-shell>/bin/caelestia-shell ipc call idleInhibitor disable
<current-helper>/bin-or-store-path/axiom-caelestia-keep-awake
<caelestia-shell>/bin/caelestia-shell ipc call idleInhibitor isEnabled
```

Result:

```text
true
```

Why chosen: this verified the helper command itself works in the live graphical session; the defect was startup timing, not the direct IPC command.

## Targeted Nix Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; startup = cfg.hey.hooks.startup; keepAwakeHook = startup."07-caelestia-keep-awake"; shellHook = startup."06-caelestia-shell"; helperPath = builtins.elemAt (builtins.match ".*hey.do ([^ ]+).*" keepAwakeHook) 0; helperText = builtins.readFile helperPath; packageNames = map (p: p.name or "") cfg.users.users.c1.packages; in { shellHookStartsSession = lib.hasInfix "caelestia-session start" shellHook; keepAwakeHookAfterShell = (builtins.elem "06-caelestia-shell" (builtins.attrNames startup)) && (builtins.elem "07-caelestia-keep-awake" (builtins.attrNames startup)); helperUsesDirectShell = lib.hasInfix "/bin/caelestia-shell ipc call idleInhibitor enable" helperText; helperRetriesSixtySeconds = lib.hasInfix "seq 1 120" helperText; helperAvoidsCliPathDependency = !(lib.hasInfix "/bin/caelestia shell idleInhibitor enable" helperText); noAxiomSleepModePackage = !(lib.any (n: n == "axiom-sleep-mode") packageNames); }'
```

Result:

```json
{"helperAvoidsCliPathDependency":true,"helperRetriesSixtySeconds":true,"helperUsesDirectShell":true,"keepAwakeHookAfterShell":true,"noAxiomSleepModePackage":true,"shellHookStartsSession":true}
```

Why chosen: this directly proves the generated startup hook shape and helper retry behavior that address the race.

Note: the first attempt to read the generated helper path before building failed because the new script output had not been realized yet. After the Axiom toplevel build realized the store path, the same assertion passed.

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
- Built `hm_.localshareheyhooks.dstartup.d07caelestiakeepawake.drv`.
- Built `nixos-system-axiom-25.11.20260203.e576e3c.drv`.

Warnings observed: existing nixpkgs/specialArgs and deprecated option warnings remained present and are unrelated to this task.

## Skipped Live Checks

No full new-login smoke was run after changing the repository because the fix still needs deployment. Post-deploy smoke should start a fresh Hyprland session or restart `caelestia-session`, then run:

```sh
caelestia shell idleInhibitor isEnabled
```

Expected result: Keep Awake reports enabled after Caelestia finishes cold startup.
