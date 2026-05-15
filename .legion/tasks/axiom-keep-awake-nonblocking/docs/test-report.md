# Test Report: Axiom Keep Awake Nonblocking Startup

## Verdict

PASS

## Environment

- Worktree: `.worktrees/axiom-keep-awake-nonblocking/`
- Branch: `legion/axiom-keep-awake-nonblocking`
- Base: `origin/master` at `37893c03`
- Date: 2026-05-15

## Targeted Nix Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; startup = cfg.hey.hooks.startup; keepAwakeHook = startup."07-caelestia-keep-awake"; shellHook = startup."06-caelestia-shell"; helperPath = builtins.elemAt (builtins.match ".*nohup ([^ ]+).*" keepAwakeHook) 0; helperText = builtins.readFile helperPath; packageNames = map (p: p.name or "") cfg.users.users.c1.packages; in { shellHookStartsSession = lib.hasInfix "caelestia-session start" shellHook; keepAwakeHookAfterShell = (builtins.elem "06-caelestia-shell" (builtins.attrNames startup)) && (builtins.elem "07-caelestia-keep-awake" (builtins.attrNames startup)); keepAwakeHookUsesNohup = lib.hasInfix "/bin/nohup" keepAwakeHook; keepAwakeHookBackgrounded = lib.hasInfix "&" keepAwakeHook; keepAwakeHookSuppressesOutput = lib.hasInfix ">/dev/null 2>&1" keepAwakeHook; helperUsesDirectShell = lib.hasInfix "/bin/caelestia-shell ipc call idleInhibitor enable" helperText; helperRetriesSixtySeconds = lib.hasInfix "seq 1 120" helperText; noAxiomSleepModePackage = !(lib.any (n: n == "axiom-sleep-mode") packageNames); }'
```

Result:

```json
{"helperRetriesSixtySeconds":true,"helperUsesDirectShell":true,"keepAwakeHookAfterShell":true,"keepAwakeHookBackgrounded":true,"keepAwakeHookSuppressesOutput":true,"keepAwakeHookUsesNohup":true,"noAxiomSleepModePackage":true,"shellHookStartsSession":true}
```

Why chosen: this directly proves the change that addresses the reported slowdown. The startup hook now launches the helper asynchronously while preserving hook order, direct IPC, and the cold-start retry window.

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

- Built `hm_.localshareheyhooks.dstartup.d07caelestiakeepawake.drv`.
- Built `nixos-system-axiom-25.11.20260203.e576e3c.drv`.

Warnings observed: existing nixpkgs/specialArgs and deprecated option warnings remained present and are unrelated to this task.

## Skipped Live Checks

No new-login smoke was run from this tool session. Post-deploy smoke should start a fresh Hyprland session or restart the startup hook path, then confirm shell startup is no longer delayed by Keep Awake waiting and `caelestia shell idleInhibitor isEnabled` reports enabled after Caelestia IPC is ready.
