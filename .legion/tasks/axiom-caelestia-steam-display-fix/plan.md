# Axiom Caelestia Steam Display Fix

## Task ID
`axiom-caelestia-steam-display-fix`

## Goal
Fix Steam launchability from the Axiom Caelestia launcher by ensuring launcher-owned GUI processes inherit the active Hyprland/XWayland display environment.

## Problem
Steam currently fails with `Unable to open a connection to X` and `XOpenDisplay failed` when launched from the desktop launcher path. Live inspection shows the graphical session itself is healthy: XWayland is running on `:0`, `xrandr` can connect to it, and desktop-launched Foot/browser processes have `DISPLAY=:0`. The Caelestia session runner and `quickshell` process, however, only have Wayland/Hyprland variables and lack `DISPLAY`, so X11-first applications launched from that shell can fail before their UI opens.

## Acceptance
- Caelestia session runner and shell-launched children receive the active `DISPLAY` value when the systemd user manager knows it.
- Steam launched from the Caelestia launcher can reach the current XWayland display instead of logging `XOpenDisplay failed` from a missing display environment.
- Existing Wayland variables, Hyprland instance guarding, Qt theme variables, PATH ownership, and Caelestia duplicate-instance protection remain intact.
- Repository validation proves the generated `caelestia-session` script hydrates display variables from the session/user manager in a minimal way.
- Runtime validation records either a successful launcher-path smoke test or the precise remaining blocker if Steam still fails for a non-display reason.

## Scope
- Update repo-owned Caelestia session environment wiring only as needed to propagate `DISPLAY` and related display auth variables from the active user session.
- Validate Steam/XWayland connectivity and recent Steam log behavior on the live Axiom session.
- Add required Legion evidence for implementation, verification, review, walkthrough, and wiki writeback.

## Non-goals
- Do not debug Steam GPU, pressure-vessel, Proton, account, network, or game-specific failures unless the display environment fix is proven insufficient.
- Do not redesign the Caelestia launcher, replace `app2unit`, or change unrelated shell settings.
- Do not change global XWayland scaling, Steam HiDPI policy, Steam library migration, or login-shell behavior.
- Do not make mutable per-user shell startup edits as the durable fix.

## Assumptions
- Steam is being launched through the Caelestia launcher path when the screenshot error appears.
- The current user manager has the correct `DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-1`, and Hyprland signature after the existing `05-session` import hook.
- X11 connectivity itself is working because `xrandr` succeeds with `DISPLAY=:0` in the live session.
- Steam may still have separate runtime warnings, but those are out of scope unless they block launch after the display environment is present.

## Constraints
- Follow Legion workflow and the git-worktree PR envelope before production repo edits.
- Keep the change declarative and minimal inside the dotfiles.
- Avoid hard-coding `DISPLAY=:0` in the generated script when a session/user-manager value can be read.
- Preserve security posture by importing only display/session variables, not arbitrary user-manager environment.

## Risks
- A generated script can prove the intended environment hydration, but full launcher behavior still needs live smoke testing in the active graphical session.
- Reading user-manager environment at runtime must be narrowly scoped to avoid leaking unrelated variables into launcher children.
- If Steam still crashes after `DISPLAY` is present, the next task should split into Steam runtime/GPU investigation instead of expanding this task silently.

## Design Summary
The recommended path is to make `caelestia-session` hydrate missing display variables from the systemd user manager before launching `caelestia-shell`. The existing Hyprland startup hook already imports display variables into the user manager, so the fix should reuse that source of truth and only export a small allowlist such as `DISPLAY`, `WAYLAND_DISPLAY`, `XAUTHORITY`, `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP`, `XDG_SESSION_TYPE`, and `HYPRLAND_INSTANCE_SIGNATURE` when they are available. This keeps Caelestia's PATH and Qt ownership unchanged while allowing X11-first launcher children such as Steam to connect to XWayland.

## Phases
1. Materialize this task contract.
2. Enter the git-worktree PR envelope required for repo modifications.
3. Implement the minimal Caelestia session display environment hydration.
4. Verify generated script content, Nix evaluation/build as feasible, XWayland connectivity, and Steam launcher-path behavior.
5. Run change review, walkthrough, wiki writeback, and PR lifecycle cleanup.
