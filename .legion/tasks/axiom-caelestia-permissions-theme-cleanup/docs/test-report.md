# Test Report

## Summary

PASS. Static validation proves the Axiom NixOS configuration now adds a local-primary-user polkit allowlist for the intended NetworkManager and logind actions, preserves NetworkManager+iwd ownership, removes the Catppuccin Fcitx5 override, replaces visible Catppuccin icon/cursor packages, and still builds the Axiom toplevel.

Live destructive/session checks were intentionally skipped in this tool session and remain post-deploy smoke tests.

## Commands

### Targeted Axiom Eval

Command:

```sh
nix eval --impure --json --expr '<aggregated Axiom config assertions>'
```

Result: PASS.

Key evidence:

```json
{
  "hasNetworkManagerGroup": false,
  "polkitHasLogin1Allowlist": true,
  "polkitHasNetworkManagerAllowlist": true,
  "polkitAllowsReboot": true,
  "polkitAllowsPowerOff": true,
  "polkitAllowsSuspend": true,
  "polkitAllowsWifiToggle": true,
  "polkitAllowsNetworkControl": true,
  "polkitAvoidsLogin1PrefixGrant": true,
  "polkitAvoidsNetworkManagerPrefixGrant": true,
  "polkitRequiresLocalSubject": true,
  "polkitUsesVar": true,
  "networkManagerEnabled": true,
  "networkManagerWifiBackend": "iwd",
  "iwdEnabled": true,
  "iwdEnableNetworkConfiguration": false,
  "fcitxThemeEnabled": false,
  "fcitxHasCatppuccinAddon": false,
  "fcitxClassicUiManaged": false,
  "fcitxHasRime": true,
  "fcitxHasPinyin": true,
  "iconThemeName": "Papirus-Dark",
  "iconPackage": "papirus-icon-theme-20250501",
  "cursorThemeName": "Bibata-Modern-Classic",
  "cursorPackage": "bibata-cursors-2.0.7",
  "caelestiaExecStart": "/nix/store/.../bin/caelestia-shell --no-duplicate"
}
```

Why chosen: this directly validates the changed authorization, NetworkManager/iwd, Fcitx5, theme, and Caelestia service claims without mutating live Wi-Fi or power state.

### Diff Whitespace

Command:

```sh
git diff --check
```

Result: PASS with no output.

### Axiom Toplevel Build

Command:

```sh
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Notes: initial build completed after building the changed Fcitx5, polkit rules, home-manager files, user units, system units, and `nixos-system-axiom` derivations. After review tightened the policy to require `subject.local == true` and avoid the broad `networkmanager` group grant, the same build command passed again and rebuilt the polkit rules, system units, etc, and `nixos-system-axiom` derivations. Existing repository warnings were observed for read-only pkgs, deprecated Mesa aliases, pulseaudio option rename, and `system` rename; none were introduced by this change.

## Skipped Live Checks

- Did not run `nmcli radio wifi off/on` from Caelestia because it is disruptive.
- Did not trigger reboot, poweroff, suspend, or hibernate from Caelestia because those are destructive/session-changing actions.
- Did not visually inspect Thunar icons or Fcitx5 candidate window after deployment because the built configuration has not been switched into the live session.

Post-deploy smoke checklist:

- Rebuild/switch Axiom, then restart the graphical session or `caelestia-shell.service`.
- From Caelestia, test the intended Wi-Fi/network control path and confirm it no longer reports authorization failure.
- From Caelestia, test the intended reboot/session UI path at a safe time.
- Restart Fcitx5 or relogin and visually confirm the candidate UI no longer uses Catppuccin.
- Open Thunar and confirm folder/icon colors now follow ordinary Papirus/Breeze/Graphite rather than Catppuccin folders.
