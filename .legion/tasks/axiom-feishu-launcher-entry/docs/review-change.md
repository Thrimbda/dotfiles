# Change Review

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: `hosts/axiom/default.nix` adds `bytedance-feishu.desktop` to Axiom's Caelestia launcher favourites.
- In scope: `hosts/axiom/default.nix` adds an Axiom-only `caelestia-shell.service` pre-start script that appends the same favourite to an existing mutable `~/.config/caelestia/shell.json` without replacing other settings.
- In scope: task-local Legion evidence under `.legion/tasks/axiom-feishu-launcher-entry/**`.
- No other host, launcher architecture, Feishu account/cache/proxy/autostart data, secret, or runtime credential configuration changed.

## Correctness Review

- `Super+Space` is the generated Hyprland keybind for `caelestia shell drawers toggle launcher`, so adding the entry through Caelestia launcher configuration targets the reported menu.
- Feishu's upstream package provides the desktop id `bytedance-feishu.desktop`; using that id matches Caelestia's `favouriteApps` model and avoids a duplicate desktop entry.
- The mutable-config updater is ordered after the existing Caelestia seed scripts, so missing or old Nix-store symlink configs still get seeded before the favourite append runs.
- The updater preserves existing JSON content and only appends the Feishu id when it is absent.
- Verification confirms the favourite setting, pre-start hook, package presence, updater script syntax, and Axiom toplevel evaluation.

## Security Review

- Security trigger considered: the change writes user-local shell configuration from a systemd user service.
- The service runs as the logged-in user, writes only the user's Caelestia `shell.json`, and does not touch secrets, credentials, Feishu account state, system policy, or privileged paths.
- No trust-boundary expansion, auth change, token handling, or user-controlled shell execution is introduced.

## Residual Risks

- Live launcher rendering and app launch still require a real Axiom Wayland session after deployment.
- If the existing user `shell.json` is invalid JSON or has an unexpected `launcher.favouriteApps` type, the updater logs a warning and leaves the file unchanged rather than blocking Caelestia startup.
