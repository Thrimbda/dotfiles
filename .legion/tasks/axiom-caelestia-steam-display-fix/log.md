# Log

## 2026-05-15
- User reported Steam cannot open and provided a screenshot saying `Unable to open a connection to X`.
- Legion workflow entry gate was explicitly requested; no restore task id was provided, so this task entered brainstorm rather than restoring the older `axiom-desktop-session-path-steam-fix` task.
- Read the completed `axiom-desktop-session-path-steam-fix` task and wiki as context. That task fixed desktop PATH propagation and explicitly left future Steam runtime/display failures to a separate task.
- Live diagnostics: OpenCode's own shell is outside the graphical session, but the machine has Hyprland pid `2542` and `Xwayland :0` pid `2630` running.
- Live diagnostics: systemd user manager environment contains `DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-1`, `XDG_RUNTIME_DIR=/run/user/1000`, and the current `HYPRLAND_INSTANCE_SIGNATURE`.
- Live diagnostics: `DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 xrandr --query` succeeds, proving XWayland is reachable.
- Live diagnostics: Foot and Zen processes include `DISPLAY=:0`, but `caelestia-session` and `quickshell` only include Wayland/Hyprland variables and lack `DISPLAY`.
- Steam log evidence at `~/.local/share/Steam/logs/console-linux.txt` lines 4888-5030 shows repeated `CBaseLinuxUpdateUI::BaseCreateWindow: XOpenDisplay failed`, `Unable to open display`, and Steam crashes around `2026-05-15 20:35-20:36`.
- User confirmed the scope: continue fixing Caelestia/launcher display propagation and do not expand into Steam GPU/runtime/Proton unless the display fix leaves a new blocker.
- Opened git-worktree PR envelope from `origin/master` on branch `legion/axiom-caelestia-steam-display-fix-display-env` at `.worktrees/axiom-caelestia-steam-display-fix`.
- Implemented a minimal `caelestia-session` change: `session_env()` now reads the systemd user manager environment and imports only missing display/session variables from a fixed allowlist before launching Caelestia Shell.
- Engineer local checks passed: `git diff --check`; `nix eval --impure --raw '.#nixosConfigurations.axiom.config.modules.desktop.caelestia.session.controlCommand'` evaluated the generated control command.
- Verification passed. `git diff --check`, generated control-command eval, generated script syntax, and full `axiom` toplevel build passed. The generated script contains the display-variable allowlist, and a live restart with the new script gave `DISPLAY=:0` to both `caelestia-session` and `quickshell`.
- Steam smoke launch with launcher-like environment no longer logged `XOpenDisplay failed` or `Unable to open display`; it progressed into Steam initialization. A later `Download failed: http error 0` is recorded as outside the display-environment scope unless it becomes the next blocker.
- Change review passed with a session-environment security lens. No blocking findings; production scope is limited to `modules/desktop/caelestia.nix`.
- Walkthrough and PR body generated from existing implementation, verification, and review evidence.
- Wiki writeback completed: added task summary and updated current Axiom Caelestia decisions/patterns for display-session hydration of launcher-owned apps.
- Committed and pushed branch `legion/axiom-caelestia-steam-display-fix-display-env`; opened PR https://github.com/Thrimbda/dotfiles/pull/62 against `master`.
