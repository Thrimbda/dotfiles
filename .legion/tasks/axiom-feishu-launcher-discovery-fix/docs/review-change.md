# Change Review

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: `hosts/axiom/default.nix` adds an Axiom-local `XDG_DATA_DIRS` environment value for `caelestia-shell.service`.
- In scope: task-local Legion evidence under `.legion/tasks/axiom-feishu-launcher-discovery-fix/**`.
- No other host, launcher architecture, Feishu account/cache/proxy/autostart data, secret, credential, or organization policy changed.

## Correctness Review

- The upstream launcher consumes `DesktopEntries.applications`; Quickshell discovers those entries from `$XDG_DATA_HOME/applications` and `$XDG_DATA_DIRS/*/applications`.
- The previous configuration already had `bytedance-feishu.desktop` as a favourite, but that favourite cannot render if the app database cannot see the desktop entry.
- The new service environment is attached to the Caelestia shell process itself, so it is present before Quickshell performs its desktop-entry scan.
- The evaluated `XDG_DATA_DIRS` includes Feishu's package `share` path, and the Feishu package still contains `share/applications/bytedance-feishu.desktop`.
- The existing favourite config and mutable `shell.json` pre-start updater remain intact.

## Security Review

- Security trigger considered: service environment controls lookup paths for a user-session launcher process.
- The service is a systemd user service, the paths come from Nix-evaluated package closures, and no privileged path, secret, token, account state, or trust boundary is changed.
- No user-controlled shell execution is introduced; launcher execution still uses upstream desktop-entry parsing and `app2unit` behavior.

## Verification Review

- `docs/test-report.md` records focused evals for `XDG_DATA_DIRS`, Feishu desktop-entry existence, favourite config, package presence, pre-start hook preservation, Axiom toplevel evaluation, and whitespace.
- Live launcher rendering remains a valid residual risk because this environment cannot run the real Axiom Wayland layer-shell session.

## Residual Risks

- The first live confirmation still requires deploying the NixOS configuration, restarting `caelestia-shell.service` or starting a new Hyprland session, opening `Super+Space`, and confirming Feishu appears and launches.
