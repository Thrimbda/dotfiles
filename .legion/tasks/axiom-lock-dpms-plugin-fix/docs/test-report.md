# Test Report: Axiom Caelestia Lock DPMS Behavior

Result: PASS. The secure-gated DPMS-off path, native key/pointer wake while
locked, same-epoch no-rearm behavior, and timer-owned DPMS unlock cleanup were
all captured in a controlled live session.

## Why These Checks

The change crosses three boundaries: patched QML behavior, generated Hyprland
Lua, and the live compositor/session. The checks below first prove the patch and
Nix integration, then inspect the deployed values and finally exercise display
power transitions. A full system build was used because the new host policy is
materialized through Home Manager rather than the Caelestia package alone.

## Patch And Source Assertions

```sh
patch --batch --fuzz=0 -p1 -d <clean-caelestia-source> \
  < modules/desktop/caelestia-lock-dpms-config.patch
patch --batch --fuzz=0 -p1 -d <clean-caelestia-source> \
  < modules/desktop/caelestia-lock-dpms-shell.patch
node modules/desktop/tests/caelestia-lock-dpms-patch-test.js \
  <clean-fully-patched-source> \
  /nix/store/qnq2h0frlvlflak559zmy1y66zdd6br3-caelestia-qml-plugin/lib/qt-6/qml/Caelestia/Config/caelestia-config.qmltypes
```

Passed. Both patches applied with zero fuzz. The Node test verifies the Config
schema, secure-gated `onSecureChanged` arming, unlock-only `onLockedChanged`
cleanup, timer guards, and wake-state invariants.

```sh
node --check modules/desktop/tests/caelestia-lock-dpms-patch-test.js
```

Passed with no output.

## Build And Generated Configuration

```sh
nix build --no-link --impure \
  .#nixosConfigurations.axiom.config.modules.desktop.caelestia.package
nixos-rebuild build --flake .#axiom --impure -L
```

Passed. The patched shell output is:

```text
/nix/store/hnxvrh9cd709kdn0qr8jhycjs36ng25s-caelestia-shell-1.0.0
```

The final source evaluation produced:

```text
/nix/store/9gbv1i8w12y96wyqbcvdvxfrnhgrk8nk-nixos-system-axiom-26.05.7813.0dd31db7e6db
```

Evaluation of `hypr/custom/general.lua` confirmed valid Lua comments and both
generated settings:

```lua
misc = {
  key_press_enables_dpms = true,
  mouse_move_enables_dpms = true,
}
```

## Deployed Runtime

The worktree configuration was activated with:

```sh
sudo nixos-rebuild switch \
  --flake /home/c1/dotfiles/.worktrees/axiom-lock-dpms-plugin-fix#axiom \
  --impure
```

Runtime evidence after activation:

- The deployed shell and host wake policy are active. The currently running
  restoration closure additionally writes the original-default Howdy and
  fingerprint values as `true`; the final source contains no authentication
  override and evaluates to the closure above.
- The sole QuickShell instance uses the patched `hnxvr...-caelestia-shell` path.
- Its process maps the patched Config plugin
  `/nix/store/qnq2h0frlvlflak559zmy1y66zdd6br3-caelestia-qml-plugin/.../libcaelestia-configplugin.so`.
- `~/.config/caelestia/shell.json` still reports `lockDpmsTimeout = 60`.
- `hyprctl getoption misc:key_press_enables_dpms` and
  `misc:mouse_move_enables_dpms` both report `bool: true` and `set: true`.

## Physical Smoke

### Secure-Gated DPMS Off

A manual `caelestia shell lock lock` was left active for 65 seconds. Both
monitors then reported `dpmsStatus: false`, while Hyprland reported `LOCK` for
both. This proves the timer arms from the compositor-confirmed secure state.

### Key Press Wake While Locked

After a separate 65-second lock cycle reached DPMS off, the user pressed local
`Shift`. The displays returned and the user observed the lock screen remained
present before completing authentication. The later programmatic sample was
unlocked because authentication had already completed.

### Pointer Motion Wake

Before strict automated testing, direct compositor motion wake was also checked:

```sh
hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
```

The user moved the physical mouse without clicking; both monitors returned to
`dpmsStatus: true`.

### Controlled Locked Pointer Wake And No Rearm

Automatic Howdy and fingerprint authentication were temporarily disabled through
the existing mutable Axiom config with user approval, then restored to `true`
afterward. This prevented unrelated authentication from ending the test lock.

The controlled cycle produced all of these programmatic samples:

1. At 65 seconds, both monitors were `dpmsStatus: false`, both had `LOCK`, and
   `caelestia shell lock isLocked` returned `true`.
2. `YDOTOOL_SOCKET=/run/ydotoold/socket ydotool mousemove -x 1 -y 0` restored
   both monitors to `dpmsStatus: true` while both still had `LOCK` and the lock
   IPC still returned `true`.
3. After a further 65 seconds without Wayland input, both monitors remained on,
   both still had `LOCK`, and the lock IPC remained `true`.

This proves the native pointer-motion path wakes a locked display and the lock
timer does not rearm within the same lock epoch.

### Timer-Owned DPMS Unlock Cleanup

In a fresh lock cycle, both monitors were off with `LOCK` and IPC state `true`
after 65 seconds. The user-authorized local `caelestia shell lock unlock` call
then produced `dpmsStatus: true` on both monitors, no `LOCK` blocker, and IPC
state `false`. This verifies the unlock cleanup restores timer-owned DPMS.

### Authentication Restoration

After the controlled cycles, a separate restoration generation wrote
`enableHowdy = true` and `enableFprint = true` back to
`~/.config/caelestia/shell.json`. A restarted single shell and the final runtime
check both confirmed these values are true. The temporary source fields were
removed before final delivery.

## Limitations

- The former QML zero-timeout `IdleMonitor` wake path remains non-authoritative;
  native Hyprland wake is the accepted implementation.
- The 900/1800-second policy was not behaviorally waited out again; the source
  and generated configuration were unchanged, while Axiom-wide native wake was
  explicitly approved.
