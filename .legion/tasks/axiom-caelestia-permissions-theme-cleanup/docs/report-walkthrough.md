# Report Walkthrough

Mode: implementation

## What Changed

- Axiom now grants Caelestia/Quickshell-owned desktop controls through a local-primary-user polkit allowlist instead of relying on active-seat classification or sudo wrappers.
- The allowlist is restricted to selected NetworkManager Wi-Fi/profile actions and selected logind reboot/poweroff/suspend/hibernate actions.
- Axiom Fcitx5 no longer enables the Catppuccin classic UI theme override.
- Autumnal visible theme assets now use ordinary `Papirus-Dark` from `papirus-icon-theme` and `Bibata-Modern-Classic` from `bibata-cursors` instead of Catppuccin-backed icon/cursor packages.

## Why

The live shell is Caelestia Shell running as a Quickshell process under `caelestia-shell.service`. That service-owned process is not equivalent to a command run in an active graphical terminal for polkit decisions, so actions that are normally allowed for an active local session can fail as `challenge` or `no`. The RFC chose a local Axiom policy boundary rather than restoring old Quickshell code or adding privileged wrappers.

Catppuccin was removed from current visible Axiom theme surfaces because it conflicts with the Caelestia/qtengine/Breeze/Graphite direction in Thunar/file explorer and Fcitx5 surfaces.

## Evidence

- RFC: `docs/rfc.md`
- RFC review: `docs/review-rfc.md` PASS
- Verification: `docs/test-report.md` PASS for targeted Axiom eval, `git diff --check`, and Axiom toplevel build
- Change review: `docs/review-change.md` PASS after tightening the initial policy to require local subjects and avoid broad group/prefix grants

## Residual Risk

- Live Caelestia/Quickshell polkit subject classification still needs post-deploy confirmation. Static eval proves the policy shape, but not whether the running user service is classified as `subject.local` by polkit on the deployed machine.
- Wi-Fi/power actions and visual theme behavior need live smoke after switching the system because they are disruptive or require the active graphical session.

## Post-Deploy Smoke

- Rebuild/switch Axiom and restart the graphical session or `caelestia-shell.service`.
- Test Caelestia Wi-Fi/network control and confirm no authorization failure.
- Test Caelestia reboot/session UI at a safe time.
- Restart Fcitx5 or relogin and confirm the candidate UI no longer uses Catppuccin.
- Open Thunar and confirm icons use the ordinary Papirus/Breeze/Graphite visual direction.
