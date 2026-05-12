# Axiom Caelestia Permissions and Theme Cleanup

## Contract

- `name`: Axiom Caelestia Permissions and Theme Cleanup
- `taskId`: `axiom-caelestia-permissions-theme-cleanup`
- `risk`: medium
- `mode`: default implementation mode with design gate

## Goal

Restore expected Axiom desktop shell control behavior and remove the visible Catppuccin/Caelestia theme mismatch without reintroducing the old repository-managed Quickshell stack.

## Problem

The active shell process is Caelestia Shell, implemented with Quickshell and launched by `caelestia-shell.service` under the systemd user manager. Live checks show the shell process is not naturally treated as the active seat subject by polkit. Actions that are allowed for an active local session can therefore degrade to `challenge` or `no` when invoked from the shell service, including logind power actions and NetworkManager Wi-Fi control.

Axiom also mixes the current Caelestia/qtengine/Breeze/Graphite direction with Catppuccin-specific visible assets. The mismatch is most visible in Thunar/file explorer icon colors and the Fcitx5 classic UI theme.

## Acceptance

- Caelestia/Quickshell remains systemd-user owned through `caelestia-shell.service`; no direct unmanaged shell start path is added.
- Axiom grants only the minimal local desktop authorization needed for the primary user shell to control expected NetworkManager Wi-Fi/network and logind power/session actions.
- The fix does not globally weaken Darwin, server, or non-Axiom host policy.
- Active Axiom theme surfaces no longer require Catppuccin for Thunar/file explorer icons or Fcitx5 classic UI.
- Rime/Pinyin engine selection and Fcitx5 Wayland frontend behavior remain unchanged.
- Static validation covers evaluated Axiom authorization settings, NetworkManager/iwd ownership, generated Fcitx5 configuration state, theme package choices, and the Axiom NixOS toplevel.
- Live validation requirements are documented for post-deploy shell restart, Wi-Fi toggle, power/session actions, Thunar icons, and Fcitx5 visual confirmation.

## Assumptions

- Axiom is a single-user workstation where the primary local desktop user is `c1`.
- Caelestia upstream remains the active product shell; the observed `quickshell` process is expected because Caelestia Shell runs on Quickshell.
- The current shell service remains under the user manager, so polkit subject activity may differ from commands run inside an active graphical terminal.
- Removing Catppuccin from the visible Axiom theme is preferable to maintaining a second accent palette alongside Caelestia/Graphite/Breeze.

## Constraints

- Keep Linux desktop changes out of Darwin imports.
- Do not restore legacy `config/quickshell` or end4 `ii` paths.
- Do not add broad passwordless administrative access unrelated to shell desktop controls.
- Do not touch Rime schemas, dictionaries, or private input data.
- Keep repository-owned Caelestia defaults small and preserve mutable user `~/.config/caelestia/shell.json` behavior.

## Scope

- Axiom host desktop/input/theme configuration.
- Local Caelestia integration module if a narrowly scoped polkit rule or package/service wiring is needed.
- Autumnal theme icon/cursor package selection if required to remove Catppuccin visible assets.
- Fcitx5 host-level theme selection.
- Task-local Legion docs, verification, review, walkthrough, and wiki writeback.

## Non-Goals

- Rebuild the old Quickshell quick-controls implementation.
- Implement full Wi-Fi onboarding, Bluetooth pairing, or a deep control center.
- Change Caelestia upstream QML source.
- Change wallpaper ownership, launcher defaults, monitor facts, or Hyprland keybind product direction except as needed for validation evidence.
- Remove every historical Catppuccin reference from docs or unrelated modules.

## Design Summary

- Treat the permission issue as a polkit/logind/NetworkManager authorization boundary caused by systemd-user shell ownership, not as a Unix file permission problem in Quickshell.
- Prefer a narrow Axiom/local-user authorization path for shell-owned desktop controls over spawning privileged commands through sudo or mutating upstream QML.
- Remove Catppuccin from current Axiom visible theme surfaces by using ordinary Papirus icons and disabling the host-level Fcitx5 Catppuccin classic UI override.
- Preserve existing NetworkManager+iwd ownership, Caelestia service ownership, and Fcitx5 input engine selection.

## Phases

- Contract: create task docs, record risk, scope, and acceptance.
- Design: write and review a short RFC for authorization and theme cleanup boundaries.
- Implementation: apply minimal Nix changes in the isolated worktree.
- Verification: run targeted Nix evals/build checks and record live-session gaps.
- Review and report: perform readiness review, walkthrough, and wiki writeback.
