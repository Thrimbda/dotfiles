# Validation Report: Lock-Scoped DPMS Timeout for Axiom

Status: PASS - focused static, configuration, and ordinary Git-backed package-build validation complete

## Scope

Validated the changed Axiom Caelestia settings, the pinned-source patch, its static Node assertions, and the exact configured package attribute. No production files, task plan, log, or task state files were changed during validation.

## Results

| Check | Result | What it proves |
| --- | --- | --- |
| `git diff --cached --check` | PASS | The current staged diff has no whitespace errors. |
| Clean pinned-source patch and Node assertions | PASS | The patch applies with `--fuzz=0` to the pinned Caelestia source and the focused static assertions pass. |
| Effective Axiom configuration evaluation | PASS | Both Caelestia settings paths enable the 60-second timeout; the 900/1800 policy remains intact; Hypridle is disabled; idle actions contain no suspend or hibernate. |
| Required `.#...package` build | PASS | With the implementation assets staged, the ordinary Git-backed flake evaluates the package and the build command completes successfully. |
| Local `path:` package build | PASS (prior diagnostic) | Before staging, this isolated the source-filtering issue and compiled the patched Caelestia package. |

## Commands And Evidence

### Staged-Diff Whitespace

```sh
git diff --cached --check
```

Result: PASS (no output, exit status 0).

### Pinned Source And Static Assertions

The pinned `caelestia-shell` input resolves from the lockfile revision `046dd3c6c3b1782f27284d5fc0e181b6021dd7c7`.

```sh
nix eval --raw --impure --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.caelestia-shell.outPath'
```

Result: PASS, resolved `/nix/store/agrxcy5ljl813mqyy2lav19bi9dwpkb0-source`.

```sh
tmpdir="$(mktemp -d "$PWD/.verify-caelestia-shell.XXXXXX")" && trap 'rm -rf "$tmpdir"' EXIT && cp -R "/nix/store/agrxcy5ljl813mqyy2lav19bi9dwpkb0-source" "$tmpdir/source" && chmod -R u+w "$tmpdir/source" && patch --batch --fuzz=0 -p1 -d "$tmpdir/source" < "modules/desktop/caelestia-lock-dpms-timeout.patch" && node "modules/desktop/tests/caelestia-lock-dpms-patch-test.js" "$tmpdir/source"
```

Result: PASS.

```text
patching file plugin/src/Caelestia/Config/generalconfig.hpp
patching file modules/IdleMonitors.qml
```

The clean temporary copy was created and removed inside this worktree. The Node test exited successfully after checking the typed default-disabled property, lock-state observer, per-epoch one-shot timer, immutable token and identity guards, unlock invalidation, and lock-preserving input wake monitor.

### Effective Axiom Configuration

```sh
nix eval --json --impure --expr 'let flake = builtins.getFlake (toString ./.); config = flake.nixosConfigurations.axiom.config; idle = config.modules.desktop.caelestia.settings.general.idle; mutableIdle = config.modules.desktop.caelestia.mutableConfig.settings.general.idle; idleActions = builtins.concatMap (timeout: [ (timeout.idleAction or "") (timeout.returnAction or "") ]) idle.timeouts; in assert idle.lockDpmsTimeout == 60; assert mutableIdle.lockDpmsTimeout == 60; assert idle == mutableIdle; assert builtins.any (timeout: timeout.timeout == 900 && timeout.idleAction == "lock") idle.timeouts; assert builtins.any (timeout: timeout.timeout == 1800 && timeout.idleAction == "dpms off" && timeout.returnAction == "dpms on") idle.timeouts; assert config.modules.desktop.hyprland.hypridle.enable == false; assert !(builtins.any (action: action == "suspend" || action == "hibernate") idleActions); { inherit idle mutableIdle idleActions; hypridleEnable = config.modules.desktop.hyprland.hypridle.enable; }'
```

Result: PASS.

```json
{
  "hypridleEnable": false,
  "idle": {
    "inhibitWhenAudio": true,
    "lockBeforeSleep": true,
    "lockDpmsTimeout": 60,
    "timeouts": [
      { "idleAction": "lock", "timeout": 900 },
      { "idleAction": "dpms off", "returnAction": "dpms on", "timeout": 1800 }
    ]
  },
  "idleActions": ["lock", "", "dpms off", "dpms on"],
  "mutableIdle": {
    "inhibitWhenAudio": true,
    "lockBeforeSleep": true,
    "lockDpmsTimeout": 60,
    "timeouts": [
      { "idleAction": "lock", "timeout": 900 },
      { "idleAction": "dpms off", "returnAction": "dpms on", "timeout": 1800 }
    ]
  }
}
```

This is an effective configuration evaluation, not a source-text check. The assertions fail closed if either settings path is not `60`, the required 900/1800 entries differ, Hypridle is enabled, or an idle/return action is `suspend` or `hibernate`.

### Package Build

Required command:

```sh
nix build --no-link .#nixosConfigurations.axiom.config.modules.desktop.caelestia.package
```

Result: PASS (exit status 0).

The required ordinary Git-backed build compiled the current package derivation:

```text
this derivation will be built:
  /nix/store/9ggw4m4bahq73l3np8zcs6z7hwj2zhhp-caelestia-shell-1.0.0.drv
building '/nix/store/9ggw4m4bahq73l3np8zcs6z7hwj2zhhp-caelestia-shell-1.0.0.drv'...
```

The staged patch and Node test assets are included by the normal Git-backed flake. This current direct build both evaluates that source and compiles the patched C++/QML package successfully.

#### Prior Staging Diagnostic

Before these assets were staged, the required normal-flake command failed before patch application or compilation because its Git-backed source excluded the untracked patch:

```text
error: path '/nix/store/631q2sclb9kra3wqzng50pf567xbn5rs-modules/desktop/caelestia-lock-dpms-timeout.patch' does not exist
```

To isolate whether the implementation itself compiled, the same configured package attribute was then built from a local `path:` flake source, which included the working-tree assets:

```sh
nix build --no-link "path:/home/c1/dotfiles/.worktrees/axiom-lock-dpms-delay#nixosConfigurations.axiom.config.modules.desktop.caelestia.package"
```

Result: PASS.

```text
this derivation will be built:
  /nix/store/bbibn4pwj6w1plw0lkagkd6b24lkaaw7-caelestia-shell-1.0.0.drv
building '/nix/store/bbibn4pwj6w1plw0lkagkd6b24lkaaw7-caelestia-shell-1.0.0.drv'...
```

This prior diagnostic confirms the actual patched Caelestia package can apply the patch and compile when all referenced implementation assets are present. The current successful normal `.` flake build independently clears the former staging-only failure.

## Skipped Live Checks

No deployed graphical-session checks were run. In particular, direct IPC lock, the 900-second lock path, `loginctl lock-session`, early unlock, rapid unlock/relock, and physical input wake after timer-owned DPMS off remain unverified. These require a running deployed Axiom graphical session; static checks and a package build cannot prove ext-idle delivery, compositor DPMS behavior, or physical display wake.

## Build And Deployment Boundary

No full NixOS system closure build or deployment was used. The requested targeted package build is the direct compile evidence for the patched C++/QML package, and `nix eval` directly proves Axiom's effective policy. A full system build would add unrelated closure work without stronger evidence for these claims, and deployment or `nixos-rebuild` was explicitly excluded from this validation.

## Remaining Validation

The static, configuration, and targeted package-build gate is PASS. The skipped live graphical-session checks above remain necessary before claiming physical DPMS and wake behavior in a deployed Axiom session.
