# Axiom Caelestia Session Runner

## Goal

Move Axiom's Caelestia Shell lifecycle out of `systemd --user` service ownership and into the live Hyprland login session so existing local-subject polkit rules apply to shell-owned NetworkManager and logind controls.

## Problem

Caelestia was started as `caelestia-shell.service` under the user manager. That made the process run outside the graphical `session-*.scope`, so polkit did not classify it as the local interactive subject even though it was owned by `c1`. The existing Axiom policy deliberately requires `subject.local == true`, so widening the polkit rule would solve the symptom by weakening the security boundary.

## Acceptance

- `caelestia-shell.service` is removed from the evaluated Axiom user services.
- A generated `caelestia-session` control command starts, stops, restarts, and reports the Caelestia shell from the Hyprland session environment.
- The Hyprland startup hook starts Caelestia after session environment import and before Keep Awake enablement.
- Existing shell setup behavior is preserved: mutable `shell.json` seed, wallpaper seed, Feishu favorite migration, launcher `XDG_DATA_DIRS`, qtengine environment, and runtime PATH coverage.
- The generated Hyprland keybinds and help text use the new control command for shell stop/restart.
- Static validation builds Axiom and verifies the generated Hyprland config.

## Scope

- `modules/desktop/caelestia.nix`
- `modules/desktop/hyprland.nix`
- `hosts/axiom/default.nix`
- `hosts/axiom/README.org`
- Legion task/wiki documentation for the new current-truth lifecycle

## Non-Goals

- Do not widen the Axiom polkit allowlist.
- Do not add `c1` to the broad `networkmanager` group.
- Do not vendor or patch upstream Caelestia QML.
- Do not replace the existing Caelestia CLI IPC keybind model.
- Do not solve live Wi-Fi onboarding or full NetworkManager UI parity.

## Assumptions

- Hyprland starts through UWSM/greetd and runs `exec-once = hey hook startup` inside the graphical login session.
- `WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE` are reliable guards for refusing headless or SSH-only shell starts.
- Quickshell `--no-duplicate` remains the right duplicate-instance guard.
- A live deployment smoke can validate actual polkit subject classification; static checks can only prove the generated ownership path.

## Constraints

- Keep the existing narrow `subject.local == true && subject.user == "c1"` polkit rule.
- Keep all generated state and local helpers inside the Nix-owned dotfiles integration boundary.
- Preserve Axiom's existing launcher, wallpaper, qtengine, and Keep Awake behavior.

## Risks

- A detached runner has less systemd journal lifecycle visibility than a user service, so status checks must use `caelestia-session status` and Quickshell logs.
- If the startup hook does not inherit the real session environment, the runner refuses to start; this is intentional to avoid recreating the polkit bug.
- Physical Wi-Fi/power controls still require live-session validation after deployment.

## Recommended Direction

Use a generated `caelestia-session` runner launched from the Hyprland startup hook after `05-session` imports environment and starts `hyprland-session.target`. The runner owns PATH, `XDG_DATA_DIRS`, Qt environment, pre-start migrations, duplicate protection, stop/restart commands, and migration of an old non-session-owned shell process.

## Phases

- Implement the session runner and remove the user service.
- Move Axiom-specific pre-start, launcher data dirs, opencode PATH, and Keep Awake wiring onto the session path.
- Update generated keybinds, README, and Legion wiki current truth.
- Validate with Nix eval/build, generated script smoke, and Hyprland config verification.
