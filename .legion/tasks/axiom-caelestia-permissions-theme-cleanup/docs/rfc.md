# RFC: Axiom Shell Authorization and Catppuccin Cleanup

## Summary

Use Axiom-local NixOS policy to make the systemd-user owned Caelestia/Quickshell process capable of expected desktop controls, and remove Catppuccin from the visible Axiom theme surfaces that currently conflict with Caelestia/qtengine/Breeze/Graphite.

## Current Evidence

- The visible shell process is `quickshell -p .../caelestia-shell --no-duplicate`, started by `caelestia-shell.service` under the user manager.
- `security.polkit.enable` is already true on Axiom.
- Evaluated `security.polkit.extraConfig` already contains NixOS NetworkManager rules that allow subjects in the `networkmanager` group to perform broad `org.freedesktop.NetworkManager.*` actions.
- Evaluated `user.extraGroups` is currently only `['wheel']`, and live `id c1` confirms `c1` is not in `networkmanager`; adding that group would work but would be broader than the local shell control requirement.
- Live `nmcli general permissions` from the tool shell reports Wi-Fi enable/disable as `no` and network control as `auth` because the process is not an active graphical seat subject.
- Live logind `CanReboot`, `CanPowerOff`, and `CanSuspend` report `challenge` outside the active graphical seat.
- Axiom's Autumnal theme currently uses `catppuccin-papirus-folders` while presenting the theme as `Papirus-Dark`; Axiom Fcitx5 currently forces `catppuccin-mocha-pink`.

## Options

### Option A: Rely on active-seat defaults and a polkit agent

This keeps policy untouched and expects Caelestia actions to originate from an active graphical session. It does not address user-manager services being classified differently by polkit, and it would still leave Wi-Fi toggles unavailable when NetworkManager returns `no` for inactive subjects.

Rejected because it does not match the observed service-owned shell process model.

### Option B: Add sudo wrappers for shell actions

This would make shell actions work by routing them through privileged command wrappers. It creates a new privilege execution path, increases attack surface, and couples upstream shell UI actions to local scripts.

Rejected because the required controls already have polkit/logind/NetworkManager policy surfaces.

### Option C: Axiom-local policy and theme cleanup

Add an Axiom-local polkit rule that allows only the local primary user to call narrow allowlists of NetworkManager Wi-Fi/profile actions and logind power actions needed by desktop shell/session UI. Replace Catppuccin-backed visible theme assets with non-Catppuccin alternatives and disable the Axiom Fcitx5 Catppuccin classic UI override.

Recommended because it fixes the observed authorization boundary at the policy layer, stays Axiom-scoped, avoids sudo wrappers, avoids the broader `networkmanager` group grant, and aligns visible theme surfaces with the current Caelestia direction.

## Design

### Authorization

- Add an Axiom-local `security.polkit.extraConfig` rule for `subject.local == true`, `subject.user == config.user.name`, and fixed action maps.
- Include NetworkManager `enable-disable-network`, `enable-disable-wifi`, `network-control`, `settings.modify.own`, `settings.modify.system`, and `wifi.scan` only. Do not grant `NetworkManager.*`, ModemManager, hostname, global DNS, sharing, reload, or sleep-wake actions.
- Include logind ordinary reboot, power-off, suspend, hibernate, and their multiple-session variants only. Do not include generic systemd unit management, hostname, timedate, udisks, ignore-inhibit actions, or arbitrary `org.freedesktop.login1.manage` actions.

### Theme

- Change Autumnal's icon package from `catppuccin-papirus-folders` to ordinary `papirus-icon-theme` while preserving the `Papirus-Dark` icon theme name.
- Change Autumnal's cursor from Catppuccin to `Bibata-Modern-Classic` from `pkgs.bibata-cursors`.
- Disable the Axiom Fcitx5 Catppuccin theme override at the host level so the module no longer installs `catppuccin-fcitx5` or force-writes `fcitx5/conf/classicui.conf`.
- Leave Fcitx5 Rime/Pinyin addons and Wayland frontend unchanged.

## Rollback

- Remove the Axiom local polkit rule to restore default active-seat authorization behavior.
- Restore Autumnal's Catppuccin icon/cursor packages and Axiom Fcitx5 `theme.flavor/accent` settings if the visual cleanup is undesirable.
- Because the Fcitx5 user config was force-managed only while theme override is enabled, deployment rollback may require restarting Fcitx5 or the graphical session to reload the restored theme.

## Verification Plan

- Evaluate `security.polkit.extraConfig` and confirm the new rule requires a local primary-user subject and includes only the intended NetworkManager/logind action allowlists.
- Evaluate NetworkManager/iwd ownership remains enabled as before.
- Evaluate Axiom Fcitx5 addons and settings to confirm Rime/Pinyin remain present while Catppuccin theme package/config is absent.
- Evaluate Autumnal GTK icon and cursor package names to confirm visible Catppuccin packages are removed.
- Build or evaluate the Axiom toplevel derivation.
- Record live-session follow-up: rebuild/switch, restart or relogin, then test Caelestia power/session actions, Wi-Fi toggle/network editor path, Thunar icons, and Fcitx5 candidate window appearance.

## Security Notes

- The polkit rule is intentionally Axiom-local, local-subject-only, user-specific, and action-allowlisted. It does not grant generic system management, package management, systemd unit control, arbitrary command execution, broad `NetworkManager.*`, ModemManager, or ignore-inhibit power actions.
- The rule allows local shell-triggered Wi-Fi/profile and power actions without an auth prompt for the primary user. This is appropriate only for the current single-user workstation assumption and should not be promoted to a shared reusable desktop default without a separate review.
