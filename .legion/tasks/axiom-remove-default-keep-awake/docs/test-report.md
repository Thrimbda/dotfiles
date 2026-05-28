# Test Report - Axiom Remove Default Keep Awake

## Summary

Result: PASS.

The change removes Axiom's default Caelestia Keep Awake startup enablement while preserving manual `idleInhibitor` commands and the aligned 900 second lock / 1800 second DPMS idle policy.

## Commands

### Targeted Nix Assertions

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; startup = cfg.hey.hooks.startup; startupNames = builtins.attrNames startup; startupText = builtins.concatStringsSep "\n" (builtins.attrValues startup); preStart = builtins.concatStringsSep "\n" cfg.modules.desktop.caelestia.session.preStart; hostText = builtins.readFile ./hosts/axiom/default.nix; idle = cfg.modules.desktop.caelestia.settings.general.idle; in { noKeepAwakeStartupHook = !(builtins.hasAttr "07-caelestia-keep-awake" startup); noDefaultIdleInhibitorEnableInStartup = !(lib.hasInfix "idleInhibitor enable" startupText); noDefaultIdleInhibitorEnableInPreStart = !(lib.hasInfix "idleInhibitor enable" preStart); noKeepAwakeHelperName = !(lib.hasInfix "axiom-caelestia-keep-awake" hostText); lockTimeout = builtins.elem { timeout = 900; idleAction = "lock"; } idle.timeouts; dpmsTimeout = builtins.elem { timeout = 1800; idleAction = "dpms off"; returnAction = "dpms on"; } idle.timeouts; onlyTwoCaelestiaTimeouts = builtins.length idle.timeouts == 2; noCaelestiaSleep = !(lib.hasInfix "suspend" (builtins.toJSON idle) || lib.hasInfix "hibernate" (builtins.toJSON idle) || lib.hasInfix "600" (builtins.toJSON idle)); }'
```

Result: PASS.

Output:

```json
{"dpmsTimeout":true,"lockTimeout":true,"noCaelestiaSleep":true,"noDefaultIdleInhibitorEnableInPreStart":true,"noDefaultIdleInhibitorEnableInStartup":true,"noKeepAwakeHelperName":true,"noKeepAwakeStartupHook":true,"onlyTwoCaelestiaTimeouts":true}
```

Why chosen: this directly proves the evaluated Axiom startup hooks no longer contain default Keep Awake enablement and the Caelestia idle timers remain 900/1800 with no sleep action.

### Focused Active Config Search

Command:

```sh
Grep pattern `caelestiaKeepAwake|axiom-caelestia-keep-awake|07-caelestia-keep-awake|idleInhibitor enable` in `hosts/axiom`.
```

Result: PASS with one expected manual-command match in `hosts/axiom/README.org`:

```text
caelestia shell idleInhibitor enable
```

Why chosen: this confirms the active host config no longer contains the removed helper or startup hook, while documenting that the manual IPC command remains available by design.

### Current-Truth Wiki Search

Command:

```sh
Grep pattern `defaults to Caelestia|enabled by default|Keep Awake UI as source of truth|07-caelestia-keep-awake|idleInhibitor enable` in `.legion/wiki/decisions.md`.
```

Result: PASS. The only match is the current decision warning not to restore default `idleInhibitor enable` startup wiring.

Why chosen: this checks the current-truth wiki decision rather than historical task summaries, which intentionally preserve prior behavior for auditability.

### Diff Whitespace

Command:

```sh
git diff --check
```

Result: PASS. No whitespace errors were reported.

Why chosen: this is a low-cost patch hygiene check before build validation.

### Axiom Toplevel Build

Command:

```sh
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS.

Warnings observed were pre-existing Nix evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `system`, and renamed `hardware.pulseaudio` options. No build failure occurred.

Why chosen: this proves the host-level NixOS configuration still evaluates and realizes generated home/session artifacts after removing the startup helper and hook.

## Skipped

- Live 15 minute idle lock and 30 minute DPMS timing tests were not run because they would disrupt the active desktop session.
- Post-deploy smoke should start a new Hyprland/Caelestia session, ensure Axiom does not force `caelestia shell idleInhibitor isEnabled` back to enabled, and manually toggle Keep Awake once if a previous persisted state is still enabled.
