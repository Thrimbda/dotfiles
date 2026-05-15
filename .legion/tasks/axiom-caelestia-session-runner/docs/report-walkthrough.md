# Report Walkthrough

## Summary

- Replaced Axiom's `caelestia-shell.service` lifecycle with a generated `caelestia-session` runner launched from the Hyprland startup hook.
- Preserved shell setup behavior: mutable config seed, wallpaper seed, Feishu migration, launcher discovery data dirs, qtengine environment, and runtime PATH.
- Kept the narrow local-subject polkit rule unchanged so Wi-Fi authorization depends on correct session ownership rather than broader privileges.

## Verification

- Axiom toplevel build passed.
- Generated control script passed syntax/status smoke.
- Evaluated Axiom no longer has `caelestia-shell` in user services.
- Startup hook ordering puts the shell runner before Keep Awake.
- Assembled Hyprland config verified with `config ok`.

## Rollout

After deployment, restart the live Hyprland session or run the generated `caelestia-session restart` from inside that session. Then validate Caelestia's process cgroup and Wi-Fi controls before considering the runtime issue closed.
