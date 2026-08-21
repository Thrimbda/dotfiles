# Test Report: Axiom Caelestia DPMS Plugin Fix

Result: PASS for static/build/closure verification; BLOCKED for deployment/runtime verification.

## Staged Diff Hygiene

```sh
git diff --cached --check
```

Passed with no output after the narrow whitespace correction.

## Clean Patch And Artifact Test

The Config patch was applied with `patch --batch --fuzz=0 -p1` to the clean plugin-only source, and the shell patch to the clean full shell source:

```text
plugin source: /nix/store/gyry56nkj2xgii2kxxjdn8rc400qllm1-source
shell source:  /nix/store/2npw4dgf5iq8x71cg4jczkanwgh4vqxv-agrxcy5ljl813mqyy2lav19bi9dwpkb0-source
```

Both applications succeeded without fuzz. The plugin source has no `modules/IdleMonitors.qml` and contains exactly one `CONFIG_GLOBAL_PROPERTY(int, lockDpmsTimeout, 0)` line. The patched shell has exactly one each of `handleLockStateChanged`, `lockDpmsTimerComponent`, and `lockDpmsWakeMonitor`.

A separate clean full source was patched with both patches using `--fuzz=0` and passed:

```sh
node modules/desktop/tests/caelestia-lock-dpms-patch-test.js \
  <clean-fully-patched-source> \
  /nix/store/qnq2h0frlvlflak559zmy1y66zdd6br3-caelestia-qml-plugin/lib/qt-6/qml/Caelestia/Config/caelestia-config.qmltypes
```

This proves the QML state-machine invariants and requires the built plugin qmltypes to register `GeneralIdle.lockDpmsTimeout` as `int`.

## Configured Package Build

```sh
nix build --no-link .#nixosConfigurations.axiom.config.modules.desktop.caelestia.package
```

Passed. The corrected shell derivation was built:

```text
/nix/store/8m1b8rszdvz1xh5ikb4rmys1w5bxi96f-caelestia-shell-1.0.0.drv
```

Current configured outputs:

```text
package: /nix/store/8nls2lbjxsg378f8iy65lrdlpam36js0-caelestia-shell-1.0.0
plugin:  /nix/store/qnq2h0frlvlflak559zmy1y66zdd6br3-caelestia-qml-plugin
```

## Current Package Assertions

An assertion-bearing `nix eval --impure --json --expr` rechecked the configured Axiom package and pinned upstream `with-cli.plugin`:

```text
original upstream plugin: /nix/store/0d7cv2q48b7d5fx7cc3bh27s1vvv1mvs-caelestia-qml-plugin
pkg.plugin:              /nix/store/qnq2h0frlvlflak559zmy1y66zdd6br3-caelestia-qml-plugin
patched plugin inputs:   1
original plugin inputs:  0
lockDpmsTimeout:         60
mutable lockDpmsTimeout: 60
timeouts:                900 lock; 1800 dpms off / dpms on
hypridle enabled:        false
suspend/hibernate:       absent
```

The direct `buildInputs` include the patched plugin once and do not include the original plugin. `nix-store --query --references /nix/store/8nls2lbjxsg378f8iy65lrdlpam36js0-caelestia-shell-1.0.0` also contains the patched plugin once and the original plugin zero times.

## Deployment/Runtime Blocker

On Axiom, the non-interactive authorization check failed:

```sh
sudo -n true
```

```text
sudo: 需要密码
```

No `nixos-rebuild switch`, Caelestia restart, or live lock/DPMS test was attempted. This is an authorization blocker, not an implementation failure: all completed static, build, package-assertion, and closure checks remain passing.

## Remaining Runtime Checks

These checks demonstrate build-time closure alignment: the configured shell's public plugin value, direct build input, realized plugin artifact, and direct output reference identify the same patched plugin, and that artifact registers `lockDpmsTimeout`.

They do not prove deployed runtime import selection, because a running QML engine can still choose plugin roots by import-path order. They also do not prove physical DPMS behavior. After deployment, restart Caelestia, record the loaded `libcaelestia-configplugin.so` path from the shell process with the original path absent, then manually lock, wait 60 seconds, verify DPMS off, and verify input wake leaves the session locked.
